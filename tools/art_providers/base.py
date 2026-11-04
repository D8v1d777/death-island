#!/usr/bin/env python3
"""
Base provider interface for character art generation.
All providers must implement this interface.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Optional, Dict, Any, List
from pathlib import Path


@dataclass
class GenerationResult:
    """Result of a generation or import operation."""
    success: bool
    view_paths: Dict[str, str]  # view_name -> file_path
    metadata: Dict[str, Any] = None
    error: str = None

    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}


@dataclass
class ProviderConfig:
    """Configuration for a provider."""
    name: str
    enabled: bool = True
    config: Dict[str, Any] = None

    def __post_init__(self):
        if self.config is None:
            self.config = {}


class BaseArtProvider(ABC):
    """Abstract base class for all art generation providers."""

    def __init__(self, config: ProviderConfig):
        self.config = config
        self.name = config.name

    @abstractmethod
    def validate_config(self) -> tuple[bool, str]:
        """
        Validate provider configuration.
        Returns: (is_valid, error_message)
        """
        pass

    @abstractmethod
    def is_available(self) -> bool:
        """
        Check if provider is available (API reachable, server running, etc.).
        Should be fast - no heavy operations.
        """
        pass

    @abstractmethod
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
        Generate or import all required views for a character.

        Args:
            reference_path: Path to reference image
            character_name: Character name (Annie, Ellie, Marie)
            character_description: Text description for prompting
            views: List of view names to generate (front, three_quarter, side, rear)
            output_dir: Directory to save generated images
            **kwargs: Provider-specific options

        Returns:
            GenerationResult with view_paths mapping view_name -> file_path
        """
        pass

    @abstractmethod
    def get_provider_info(self) -> Dict[str, Any]:
        """Return provider metadata for provenance tracking."""
        pass

    def prepare_output_dir(self, output_dir: str) -> Path:
        """Ensure output directory exists."""
        path = Path(output_dir)
        path.mkdir(parents=True, exist_ok=True)
        return path

    def validate_reference_image(self, reference_path: str) -> tuple[bool, str]:
        """Validate that reference image exists and is readable."""
        from PIL import Image
        path = Path(reference_path)
        if not path.exists():
            return False, f"Reference image not found: {reference_path}"
        try:
            with Image.open(path) as img:
                img.verify()
            # Re-open for actual use
            with Image.open(path) as img:
                img.load()
        except Exception as e:
            return False, f"Invalid reference image: {e}"
        return True, ""

    def validate_generated_images(self, view_paths: Dict[str, str], expected_views: List[str]) -> tuple[bool, str]:
        """Validate that all expected views were generated and are valid images."""
        from PIL import Image
        missing = [v for v in expected_views if v not in view_paths]
        if missing:
            return False, f"Missing views: {missing}"

        for view, path in view_paths.items():
            p = Path(path)
            if not p.exists():
                return False, f"Generated image not found: {path}"
            try:
                with Image.open(p) as img:
                    img.verify()
                with Image.open(p) as img:
                    img.load()
                # Check minimum dimensions
                if img.width < 64 or img.height < 64:
                    return False, f"Image too small ({img.width}x{img.height}): {path}"
            except Exception as e:
                return False, f"Invalid generated image {path}: {e}"
        return True, ""