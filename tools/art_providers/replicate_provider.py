#!/usr/bin/env python3
"""
Replicate provider for character art generation.
Refactored from the original generate_character_art.py.
Optional provider - requires API token.
"""

import os
import time
import base64
import requests
from pathlib import Path
from typing import Dict, Any, List, Optional
from .base import BaseArtProvider, GenerationResult, ProviderConfig


class ReplicateProvider(BaseArtProvider):
    """
    Provider that generates images via Replicate API.

    Uses direct HTTP requests to Replicate API (no replicate Python package needed).

    Requirements:
    - REPLICATE_API_TOKEN environment variable or config
    - Internet connection
    - Paid credits on Replicate account

    Models supported:
    - flux: black-forest-labs/flux-schnell
    - sdxl: stability-ai/sdxl
    """

    DEFAULT_MODELS = {
        "flux": "black-forest-labs/flux-schnell:987739f9e2e9d3e5e5c5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5",
        "sdxl": "stability-ai/sdxl:39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b",
    }

    DEFAULT_TIMEOUT = 300
    DEFAULT_POLL_INTERVAL = 5

    def __init__(self, config: ProviderConfig):
        super().__init__(config)
        self.api_token = config.config.get("api_token") or os.environ.get("REPLICATE_API_TOKEN")
        self.models = config.config.get("models", self.DEFAULT_MODELS)
        self.default_model = config.config.get("default_model", "flux")
        self.timeout = config.config.get("timeout", self.DEFAULT_TIMEOUT)
        self.poll_interval = config.config.get("poll_interval", self.DEFAULT_POLL_INTERVAL)
        self.base_url = "https://api.replicate.com/v1"
        self.headers = {
            "Authorization": f"Token {self.api_token}" if self.api_token else "",
            "Content-Type": "application/json"
        }

    def validate_config(self) -> tuple[bool, str]:
        """Validate Replicate provider configuration."""
        if not self.api_token:
            return False, "Replicate API token not provided. Set REPLICATE_API_TOKEN env var or pass in config."

        if self.default_model not in self.models:
            return False, f"Default model '{self.default_model}' not in configured models: {list(self.models.keys())}"

        return True, ""

    def is_available(self) -> bool:
        """Check if Replicate API is reachable."""
        if not self.api_token:
            return False
        try:
            response = requests.get(
                f"{self.base_url}/models",
                headers=self.headers,
                timeout=10
            )
            return response.status_code == 200
        except Exception:
            return False

    def get_provider_info(self) -> Dict[str, Any]:
        return {
            "provider": "replicate",
            "version": "1.0",
            "requires_api_key": True,
            "default_model": self.default_model,
            "available_models": list(self.models.keys()),
            "description": "Generates images via Replicate API (paid)",
        }

    def _encode_image_to_base64(self, image_path: str) -> str:
        """Encode image to base64 string."""
        with open(image_path, "rb") as f:
            return base64.b64encode(f.read()).decode("utf-8")

    def _create_prediction(self, model: str, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a prediction on Replicate."""
        url = f"{self.base_url}/predictions"
        payload = {
            "version": model,
            "input": input_data
        }
        response = requests.post(url, headers=self.headers, json=payload, timeout=30)
        response.raise_for_status()
        return response.json()

    def _get_prediction(self, prediction_id: str) -> Dict[str, Any]:
        """Get prediction status."""
        url = f"{self.base_url}/predictions/{prediction_id}"
        response = requests.get(url, headers=self.headers, timeout=30)
        response.raise_for_status()
        return response.json()

    def _wait_for_completion(self, prediction_id: str) -> Dict[str, Any]:
        """Wait for prediction to complete."""
        start_time = time.time()
        while time.time() - start_time < self.timeout:
            result = self._get_prediction(prediction_id)
            status = result.get("status")
            if status == "succeeded":
                return result
            elif status == "failed":
                raise Exception(f"Prediction failed: {result.get('error', 'Unknown error')}")
            elif status == "canceled":
                raise Exception("Prediction was canceled")
            time.sleep(self.poll_interval)
        raise TimeoutError(f"Prediction timed out after {self.timeout} seconds")

    def _download_image(self, url: str, output_path: Path) -> bool:
        """Download image from URL."""
        try:
            response = requests.get(url, stream=True, timeout=60)
            response.raise_for_status()
            with open(output_path, "wb") as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            return True
        except Exception as e:
            print(f"Failed to download {url}: {e}")
            return False

    def _generate_single_view(
        self,
        reference_path: str,
        view: str,
        character_name: str,
        character_description: str,
        output_dir: Path,
        model: str
    ) -> Optional[str]:
        """Generate a single character view."""
        view_prompts = {
            "front": "full body front view, standing pose, facing camera directly",
            "three_quarter": "full body three-quarter view, 45 degree angle, facing slightly right",
            "side": "full body side profile view, facing right",
            "rear": "full body rear view, back facing camera"
        }

        view_prompt = view_prompts.get(view, view_prompts["front"])

        prompt = (
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

        reference_b64 = self._encode_image_to_base64(reference_path)

        input_data = {
            "prompt": prompt,
            "negative_prompt": negative_prompt,
            "image": f"data:image/jpeg;base64,{reference_b64}",
            "strength": 0.7,
            "num_inference_steps": 30,
            "guidance_scale": 7.5,
            "num_outputs": 1,
        }

        try:
            print(f"    Generating {view} view via Replicate ({model})...")
            prediction = self._create_prediction(self.models[model], input_data)
            result = self._wait_for_completion(prediction["id"])
            output_urls = result.get("output", [])

            if output_urls:
                output_filename = f"{character_name.lower()}_{view}.png"
                output_path = output_dir / output_filename
                if self._download_image(output_urls[0], output_path):
                    print(f"      Saved to {output_path}")
                    return str(output_path)
            return None
        except Exception as e:
            print(f"    Error generating {view} view: {e}")
            return None

    def generate_views(
        self,
        reference_path: str,
        character_name: str,
        character_description: str,
        views: List[str],
        output_dir: str,
        **kwargs
    ) -> GenerationResult:
        """Generate all views via Replicate API."""
        output_path = self.prepare_output_dir(output_dir)
        model = kwargs.get("model", self.default_model)

        # Validate config
        valid, error = self.validate_config()
        if not valid:
            return GenerationResult(success=False, view_paths={}, error=error)

        # Validate reference image
        valid, error = self.validate_reference_image(reference_path)
        if not valid:
            return GenerationResult(success=False, view_paths={}, error=error)

        print(f"Generating {character_name} views via Replicate ({model})...")

        view_paths = {}

        for view in views:
            result = self._generate_single_view(
                reference_path, view, character_name, character_description,
                output_path, model
            )
            if result:
                view_paths[view] = result
            else:
                return GenerationResult(
                    success=False,
                    view_paths=view_paths,
                    error=f"Failed to generate {view} view"
                )

        # Validate all generated images
        valid, error = self.validate_generated_images(view_paths, views)
        if not valid:
            return GenerationResult(success=False, view_paths={}, error=error)

        metadata = {
            "provider": "replicate",
            "model": model,
            "character": character_name,
            "views_generated": list(view_paths.keys()),
        }

        return GenerationResult(
            success=True,
            view_paths=view_paths,
            metadata=metadata
        )


def create_replicate_provider(
    api_token: str = None,
    default_model: str = "flux",
    models: Dict[str, str] = None
) -> ReplicateProvider:
    """Factory function to create a Replicate provider."""
    config = ProviderConfig(
        name="replicate",
        enabled=bool(api_token or os.environ.get("REPLICATE_API_TOKEN")),
        config={
            "api_token": api_token,
            "default_model": default_model,
            "models": models or ReplicateProvider.DEFAULT_MODELS,
        }
    )
    return ReplicateProvider(config)