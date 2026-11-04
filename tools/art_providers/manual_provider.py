#!/usr/bin/env python3
"""
Manual provider for character art generation.
Imports user-provided images from a local directory.
Zero API dependency - works with browser-generated or manually created artwork.
"""

import os
import shutil
from pathlib import Path
from typing import Dict, Any, List, Optional
from .base import BaseArtProvider, GenerationResult, ProviderConfig


class ManualProvider(BaseArtProvider):
    """
    Provider that imports pre-generated images from a local directory.

    Expected workflow:
    1. User generates images via browser (Leonardo AI, Hugging Face Spaces, etc.)
    2. User downloads and organizes images in a directory with naming convention:
       {character}_{view}.png (e.g., annie_front.png, annie_three_quarter.png)
    3. Run generator with --provider manual --input ./path/to/images
    """

    # Supported image extensions
    SUPPORTED_EXTENSIONS = {'.png', '.jpg', '.jpeg', '.webp'}

    # Required views for character
    REQUIRED_VIEWS = ["front", "three_quarter", "side", "rear"]

    # View name mappings (input filename -> internal view name)
    VIEW_ALIASES = {
        "front": ["front", "front_view", "0_front"],
        "three_quarter": ["three_quarter", "3_quarter", "threequarter", "3quarter", "side_front", "1_three_quarter"],
        "side": ["side", "profile", "side_view", "2_side"],
        "rear": ["rear", "back", "back_view", "3_rear"],
    }

    def __init__(self, config: ProviderConfig):
        super().__init__(config)
        self.input_dir: Optional[Path] = None
        self.character_name: Optional[str] = None

    def validate_config(self) -> tuple[bool, str]:
        """Validate manual provider configuration."""
        input_dir = self.config.config.get("input_dir")
        if not input_dir:
            return False, "Manual provider requires 'input_dir' in config"

        path = Path(input_dir)
        if not path.exists():
            return False, f"Input directory does not exist: {input_dir}"
        if not path.is_dir():
            return False, f"Input path is not a directory: {input_dir}"

        self.input_dir = path
        return True, ""

    def is_available(self) -> bool:
        """Manual provider is always available if input directory exists."""
        return self.input_dir is not None and self.input_dir.exists()

    def get_provider_info(self) -> Dict[str, Any]:
        return {
            "provider": "manual",
            "version": "1.0",
            "requires_api_key": False,
            "description": "Imports pre-generated images from local directory",
            "input_directory": str(self.input_dir) if self.input_dir else None,
        }

    def _find_view_file(self, view: str) -> Optional[Path]:
        """Find the image file for a specific view."""
        if not self.input_dir:
            return None

        aliases = self.VIEW_ALIASES.get(view, [view])
        base_name = self.character_name.lower() if self.character_name else ""

        # Try multiple naming patterns
        patterns = []
        for alias in aliases:
            patterns.append(f"{base_name}_{alias}")
            patterns.append(alias)

        for pattern in patterns:
            for ext in self.SUPPORTED_EXTENSIONS:
                candidate = self.input_dir / f"{pattern}{ext}"
                if candidate.exists():
                    return candidate

        return None

    def _copy_to_output(self, source: Path, view: str, output_dir: Path) -> Path:
        """Copy source image to output directory with standardized naming."""
        output_filename = f"{self.character_name.lower()}_{view}.png"
        output_path = output_dir / output_filename
        shutil.copy2(source, output_path)
        return output_path

    def generate_views(
        self,
        reference_path: str,
        character_name: str,
        character_description: str,
        views: List[str],
        output_dir: str,
        **kwargs
    ) -> GenerationResult:
        """
        Import views from the input directory.

        Note: reference_path and character_description are not used for manual provider
        but are kept for interface compatibility.
        """
        self.character_name = character_name
        output_path = self.prepare_output_dir(output_dir)

        # Validate input directory
        valid, error = self.validate_config()
        if not valid:
            return GenerationResult(success=False, view_paths={}, error=error)

        # Find and copy each required view
        view_paths = {}
        missing_views = []

        for view in views:
            source_file = self._find_view_file(view)
            if source_file:
                dest_path = self._copy_to_output(source_file, view, output_path)
                view_paths[view] = str(dest_path)
                print(f"  Imported {view}: {source_file.name} -> {dest_path.name}")
            else:
                missing_views.append(view)
                print(f"  MISSING: {view} (tried: {[f'{character_name.lower()}_{a}' for a in self.VIEW_ALIASES.get(view, [view])]})")

        if missing_views:
            # Check if ANY views were found
            if not view_paths:
                return GenerationResult(
                    success=False,
                    view_paths={},
                    error=f"No images found in {self.input_dir} for {character_name}. Expected files like: {character_name.lower()}_front.png, {character_name.lower()}_three_quarter.png, etc."
                )
            else:
                # Partial success - some views missing
                return GenerationResult(
                    success=False,
                    view_paths=view_paths,
                    error=f"Missing required views: {missing_views}. Found: {list(view_paths.keys())}"
                )

        # Validate all generated images
        valid, error = self.validate_generated_images(view_paths, views)
        if not valid:
            return GenerationResult(success=False, view_paths={}, error=error)

        # Add provenance metadata
        metadata = {
            "provider": "manual",
            "source_directory": str(self.input_dir),
            "character": character_name,
            "views_imported": list(view_paths.keys()),
        }

        return GenerationResult(
            success=True,
            view_paths=view_paths,
            metadata=metadata
        )


def create_manual_provider(input_dir: str) -> ManualProvider:
    """Factory function to create a manual provider with input directory."""
    config = ProviderConfig(
        name="manual",
        enabled=True,
        config={"input_dir": input_dir}
    )
    return ManualProvider(config)