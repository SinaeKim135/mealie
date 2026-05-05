from pydantic import BaseModel, ConfigDict, Field

from mealie.schema._mealie import MealieModel

# TODO: Should these exist?!?!?!?!?


class RecipeSlug(MealieModel):
    slug: str


class SlugResponse(BaseModel):
    model_config = ConfigDict(json_schema_extra={"example": "adult-mac-and-cheese"})


class UpdateImageResponse(BaseModel):
    image: str


class RecipeDuplicate(BaseModel):
    name: str | None = None


class RecipeScaleRequest(MealieModel):
    """Request to scale a recipe to a new yield quantity.

    The endpoint computes a scale factor as ``new_yield_quantity / current_yield_quantity``
    and multiplies every ingredient quantity by it. The recipe is NOT persisted —
    callers receive the scaled recipe and may PUT it back to save.
    """

    new_yield_quantity: float = Field(
        gt=0,
        le=10000,
        description=(
            "Target yield quantity (e.g. servings). Must be > 0 and <= 10000 to guard "
            "against accidental floating-point overflow on ingredient math."
        ),
    )
