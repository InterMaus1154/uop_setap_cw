from pydantic import BaseModel, ConfigDict


class CategoryLevelResponse(BaseModel):
    """Schema for category level response"""
    cat_level_id: int
    cat_level_name: str
    cat_level_ttl_mins: int

    model_config = ConfigDict(from_attributes=True)


class CategoryResponse(BaseModel):
    """Schema for category response"""
    cat_id: int
    cat_level_id: int
    cat_name: str

    model_config = ConfigDict(from_attributes=True)


class SubCategoryResponse(BaseModel):
    """Schema for sub category response"""
    sub_cat_id: int
    cat_id: int
    sub_cat_name: str

    model_config = ConfigDict(from_attributes=True)
