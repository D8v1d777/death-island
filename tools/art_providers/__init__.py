"""
Art Providers Package for Death Island Character Art Generation.

Provides a unified interface for multiple image generation backends:
- Manual: Import pre-generated images from local directory (zero API)
- ComfyUI: Local/remote ComfyUI HTTP API (optional, no API key)
- Replicate: Cloud API (optional, requires API token)

Usage:
    from tools.art_providers import create_provider, ProviderRegistry

    # Create a provider
    provider = create_provider("manual", input_dir="./my_artwork")

    # Or use registry for auto-detection
    registry = ProviderRegistry()
    provider = registry.get_provider("manual", input_dir="./my_artwork")
"""

from .base import BaseArtProvider, GenerationResult, ProviderConfig
from .manual_provider import ManualProvider, create_manual_provider
from .comfyui_provider import ComfyUIProvider, create_comfyui_provider
from .replicate_provider import ReplicateProvider, create_replicate_provider


class ProviderRegistry:
    """Registry for managing available providers."""

    _providers = {
        "manual": ManualProvider,
        "comfyui": ComfyUIProvider,
        "replicate": ReplicateProvider,
    }

    _factories = {
        "manual": create_manual_provider,
        "comfyui": create_comfyui_provider,
        "replicate": create_replicate_provider,
    }

    @classmethod
    def get_provider_class(cls, name: str):
        """Get provider class by name."""
        if name not in cls._providers:
            raise ValueError(f"Unknown provider: {name}. Available: {list(cls._providers.keys())}")
        return cls._providers[name]

    @classmethod
    def create_provider(cls, name: str, **config) -> BaseArtProvider:
        """Create a provider instance with configuration."""
        if name not in cls._factories:
            raise ValueError(f"Unknown provider: {name}. Available: {list(cls._factories.keys())}")
        return cls._factories[name](**config)

    @classmethod
    def list_providers(cls) -> List[str]:
        """List available provider names."""
        return list(cls._providers.keys())

    @classmethod
    def get_available_providers(cls, **common_config) -> List[str]:
        """Get list of providers that are currently available/configured."""
        available = []
        for name, factory in cls._factories.items():
            try:
                # Try to create with minimal config for availability check
                provider = factory(**common_config)
                if provider.is_available():
                    available.append(name)
            except Exception:
                pass
        return available

    @classmethod
    def check_provider_availability(cls) -> Dict[str, str]:
        """Check availability status of all providers without requiring full config."""
        status = {}
        for name in cls._providers:
            try:
                # Try to instantiate with empty config for basic check
                if name == "manual":
                    # Manual provider needs at least an input_dir for full check
                    # Just check if the class can be imported
                    status[name] = "✓ ready (requires --input)"
                elif name == "comfyui":
                    provider = cls._factories[name]()
                    status[name] = "✓ available" if provider.is_available() else "✗ server not reachable"
                elif name == "replicate":
                    provider = cls._factories[name]()
                    status[name] = "✓ available" if provider.is_available() else "✗ no API token/connection"
                else:
                    status[name] = "? unknown"
            except Exception as e:
                status[name] = f"✗ error - {e}"
        return status


def create_provider(name: str, **config) -> BaseArtProvider:
    """Convenience function to create a provider."""
    return ProviderRegistry.create_provider(name, **config)


__all__ = [
    "BaseArtProvider",
    "GenerationResult",
    "ProviderConfig",
    "ManualProvider",
    "ComfyUIProvider",
    "ReplicateProvider",
    "ProviderRegistry",
    "create_provider",
    "create_manual_provider",
    "create_comfyui_provider",
    "create_replicate_provider",
]