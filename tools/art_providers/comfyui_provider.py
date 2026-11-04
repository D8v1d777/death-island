#!/usr/bin/env python3
"""
ComfyUI provider for character art generation.
Connects to a local or remote ComfyUI server via HTTP API.
"""

import json
import time
import uuid
import requests
from pathlib import Path
from typing import Dict, Any, List, Optional
from .base import BaseArtProvider, GenerationResult, ProviderConfig


class ComfyUIProvider(BaseArtProvider):
    """
    Provider that generates images via ComfyUI HTTP API.

    ComfyUI is a node-based image generation system that exposes a local HTTP API.

    Requirements:
    - ComfyUI server running (default: http://127.0.0.1:8188)
    - Appropriate workflow JSON for character generation
    - Models installed on the ComfyUI machine (not on Android phone)

    Configuration:
    - comfyui_url: Base URL of ComfyUI server
    - workflow_path: Path to workflow JSON file
    - timeout: Request timeout in seconds
    - poll_interval: Status polling interval in seconds
    """

    DEFAULT_URL = "http://127.0.0.1:8188"
    DEFAULT_TIMEOUT = 300
    DEFAULT_POLL_INTERVAL = 5

    # Default workflow for character generation (img2img with ControlNet for pose)
    # This is a minimal example - users should provide their own workflow
    DEFAULT_WORKFLOW = {
        "3": {
            "inputs": {
                "seed": 0,
                "steps": 20,
                "cfg": 7.0,
                "sampler_name": "euler_ancestral",
                "scheduler": "normal",
                "denoise": 0.7,
                "model": ["4", 0],
                "positive": ["6", 0],
                "negative": ["7", 0],
                "latent_image": ["5", 0]
            },
            "class_type": "KSampler",
            "_meta": {"title": "KSampler"}
        },
        "4": {
            "inputs": {
                "ckpt_name": "sd_xl_base_1.0.safetensors"
            },
            "class_type": "CheckpointLoaderSimple",
            "_meta": {"title": "Load Checkpoint"}
        },
        "5": {
            "inputs": {
                "width": 1024,
                "height": 1024,
                "batch_size": 1
            },
            "class_type": "EmptyLatentImage",
            "_meta": {"title": "Empty Latent Image"}
        },
        "6": {
            "inputs": {
                "text": "character prompt",
                "clip": ["4", 1]
            },
            "class_type": "CLIPTextEncode",
            "_meta": {"title": "Positive Prompt"}
        },
        "7": {
            "inputs": {
                "text": "negative prompt",
                "clip": ["4", 1]
            },
            "class_type": "CLIPTextEncode",
            "_meta": {"title": "Negative Prompt"}
        },
        "8": {
            "inputs": {
                "samples": ["3", 0],
                "vae": ["4", 2]
            },
            "class_type": "VAEDecode",
            "_meta": {"title": "VAE Decode"}
        },
        "9": {
            "inputs": {
                "filename_prefix": "character",
                "images": ["8", 0]
            },
            "class_type": "SaveImage",
            "_meta": {"title": "Save Image"}
        }
    }

    def __init__(self, config: ProviderConfig):
        super().__init__(config)
        self.comfyui_url = config.config.get("comfyui_url", self.DEFAULT_URL).rstrip("/")
        self.workflow_path = config.config.get("workflow_path")
        self.timeout = config.config.get("timeout", self.DEFAULT_TIMEOUT)
        self.poll_interval = config.config.get("poll_interval", self.DEFAULT_POLL_INTERVAL)
        self.workflow = None
        self._client_id = str(uuid.uuid4())

    def validate_config(self) -> tuple[bool, str]:
        """Validate ComfyUI provider configuration."""
        # URL validation
        if not self.comfyui_url.startswith(("http://", "https://")):
            return False, f"Invalid ComfyUI URL: {self.comfyui_url}"

        # Load workflow if provided
        if self.workflow_path:
            path = Path(self.workflow_path)
            if not path.exists():
                return False, f"Workflow file not found: {self.workflow_path}"
            try:
                with open(path) as f:
                    self.workflow = json.load(f)
            except json.JSONDecodeError as e:
                return False, f"Invalid workflow JSON: {e}"
        else:
            # Use default workflow (will need customization per character)
            self.workflow = self.DEFAULT_WORKFLOW.copy()

        return True, ""

    def is_available(self) -> bool:
        """Check if ComfyUI server is reachable."""
        try:
            response = requests.get(f"{self.comfyui_url}/system_stats", timeout=5)
            return response.status_code == 200
        except Exception:
            return False

    def get_provider_info(self) -> Dict[str, Any]:
        return {
            "provider": "comfyui",
            "version": "1.0",
            "requires_api_key": False,
            "comfyui_url": self.comfyui_url,
            "workflow_path": self.workflow_path,
            "description": "Generates images via ComfyUI HTTP API",
        }

    def _queue_prompt(self, workflow: Dict[str, Any]) -> Optional[str]:
        """Queue a prompt and return the prompt ID."""
        try:
            payload = {
                "prompt": workflow,
                "client_id": self._client_id
            }
            response = requests.post(
                f"{self.comfyui_url}/prompt",
                json=payload,
                timeout=30
            )
            response.raise_for_status()
            result = response.json()
            return result.get("prompt_id")
        except Exception as e:
            print(f"Failed to queue prompt: {e}")
            return None

    def _wait_for_completion(self, prompt_id: str) -> bool:
        """Wait for prompt to complete by polling history."""
        start_time = time.time()
        while time.time() - start_time < self.timeout:
            try:
                response = requests.get(
                    f"{self.comfyui_url}/history/{prompt_id}",
                    timeout=10
                )
                if response.status_code == 200:
                    history = response.json()
                    if prompt_id in history:
                        prompt_data = history[prompt_id]
                        if prompt_data.get("status", {}).get("completed", False):
                            return True
                        if prompt_data.get("status", {}).get("status_str") == "error":
                            print(f"ComfyUI generation error: {prompt_data.get('status', {}).get('error')}")
                            return False
            except Exception as e:
                print(f"Error checking history: {e}")

            time.sleep(self.poll_interval)

        print(f"ComfyUI generation timed out after {self.timeout}s")
        return False

    def _get_output_images(self, prompt_id: str) -> List[str]:
        """Retrieve output image paths from ComfyUI history."""
        try:
            response = requests.get(
                f"{self.comfyui_url}/history/{prompt_id}",
                timeout=10
            )
            response.raise_for_status()
            history = response.json()

            if prompt_id not in history:
                return []

            prompt_data = history[prompt_id]
            outputs = prompt_data.get("outputs", {})

            image_paths = []
            for node_id, node_output in outputs.items():
                images = node_output.get("images", [])
                for img in images:
                    # ComfyUI returns relative paths from output directory
                    filename = img.get("filename")
                    subfolder = img.get("subfolder", "")
                    if filename:
                        if subfolder:
                            image_paths.append(f"{subfolder}/{filename}")
                        else:
                            image_paths.append(filename)

            return image_paths
        except Exception as e:
            print(f"Failed to get output images: {e}")
            return []

    def _download_image(self, image_path: str, output_path: Path) -> bool:
        """Download image from ComfyUI output directory."""
        try:
            # ComfyUI serves images at /view?filename=...&subfolder=...
            params = {"filename": Path(image_path).name}
            subfolder = str(Path(image_path).parent)
            if subfolder and subfolder != ".":
                params["subfolder"] = subfolder

            response = requests.get(
                f"{self.comfyui_url}/view",
                params=params,
                timeout=30,
                stream=True
            )
            response.raise_for_status()

            with open(output_path, "wb") as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            return True
        except Exception as e:
            print(f"Failed to download image {image_path}: {e}")
            return False

    def _prepare_workflow_for_view(
        self,
        reference_path: str,
        view: str,
        character_name: str,
        character_description: str
    ) -> Dict[str, Any]:
        """Prepare workflow for a specific view. Override for custom workflows."""
        import copy
        workflow = copy.deepcopy(self.workflow)

        # View-specific prompts
        view_prompts = {
            "front": "full body front view, standing pose, facing camera directly",
            "three_quarter": "full body three-quarter view, 45 degree angle, facing slightly right",
            "side": "full body side profile view, facing right",
            "rear": "full body rear view, back facing camera"
        }

        view_prompt = view_prompts.get(view, view_prompts["front"])

        # Build full prompt
        positive_prompt = (
            f"{character_description}, {view_prompt}, "
            "2.5D isometric game character sprite, pixel art style, "
            "transparent background, clean edges, game-ready asset, "
            "consistent lighting, orthographic projection, "
            "high quality, detailed, professional game art"
        )

        negative_prompt = (
            "background, watermark, text, logo, label, frame, border, "
            "low quality, blurry, distorted, deformed, ugly, "
            "duplicate, multiple characters, cropped, cut off, "
            "shadow on ground, perspective distortion"
        )

        # Update workflow - this depends on the specific workflow structure
        # Users should customize this for their workflow
        for node_id, node in workflow.items():
            if node.get("class_type") == "CLIPTextEncode":
                text_input = node["inputs"].get("text", "")
                if "negative" in text_input.lower() or "negative" in node.get("_meta", {}).get("title", "").lower():
                    node["inputs"]["text"] = negative_prompt
                elif "positive" in text_input.lower() or "positive" in node.get("_meta", {}).get("title", "").lower() or text_input == "character prompt":
                    node["inputs"]["text"] = positive_prompt

        return workflow

    def generate_views(
        self,
        reference_path: str,
        character_name: str,
        character_description: str,
        views: List[str],
        output_dir: str,
        **kwargs
    ) -> GenerationResult:
        """Generate all views via ComfyUI."""
        output_path = self.prepare_output_dir(output_dir)

        # Validate config
        valid, error = self.validate_config()
        if not valid:
            return GenerationResult(success=False, view_paths={}, error=error)

        # Check server availability
        if not self.is_available():
            return GenerationResult(
                success=False,
                view_paths={},
                error=f"ComfyUI server not available at {self.comfyui_url}. Is it running?"
            )

        # Validate reference image
        valid, error = self.validate_reference_image(reference_path)
        if not valid:
            return GenerationResult(success=False, view_paths={}, error=error)

        print(f"Generating {character_name} views via ComfyUI ({self.comfyui_url})...")

        view_paths = {}

        for view in views:
            print(f"  Generating {view} view...")

            # Prepare workflow for this view
            workflow = self._prepare_workflow_for_view(
                reference_path, view, character_name, character_description
            )

            # Queue prompt
            prompt_id = self._queue_prompt(workflow)
            if not prompt_id:
                return GenerationResult(
                    success=False,
                    view_paths=view_paths,
                    error=f"Failed to queue prompt for {view} view"
                )

            # Wait for completion
            if not self._wait_for_completion(prompt_id):
                return GenerationResult(
                    success=False,
                    view_paths=view_paths,
                    error=f"Generation failed or timed out for {view} view"
                )

            # Get output images
            image_paths = self._get_output_images(prompt_id)
            if not image_paths:
                return GenerationResult(
                    success=False,
                    view_paths=view_paths,
                    error=f"No output images for {view} view"
                )

            # Download first image (assuming single output)
            output_filename = f"{character_name.lower()}_{view}.png"
            local_path = output_path / output_filename

            if self._download_image(image_paths[0], local_path):
                view_paths[view] = str(local_path)
                print(f"    Saved to {local_path}")
            else:
                return GenerationResult(
                    success=False,
                    view_paths=view_paths,
                    error=f"Failed to download image for {view} view"
                )

        # Validate all generated images
        valid, error = self.validate_generated_images(view_paths, views)
        if not valid:
            return GenerationResult(success=False, view_paths={}, error=error)

        metadata = {
            "provider": "comfyui",
            "comfyui_url": self.comfyui_url,
            "character": character_name,
            "views_generated": list(view_paths.keys()),
        }

        return GenerationResult(
            success=True,
            view_paths=view_paths,
            metadata=metadata
        )


def create_comfyui_provider(
    comfyui_url: str = None,
    workflow_path: str = None,
    timeout: int = None
) -> ComfyUIProvider:
    """Factory function to create a ComfyUI provider."""
    config = ProviderConfig(
        name="comfyui",
        enabled=True,
        config={
            "comfyui_url": comfyui_url or ComfyUIProvider.DEFAULT_URL,
            "workflow_path": workflow_path,
            "timeout": timeout or ComfyUIProvider.DEFAULT_TIMEOUT,
        }
    )
    return ComfyUIProvider(config)