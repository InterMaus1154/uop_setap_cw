from fastapi import APIRouter, HTTPException
from fastapi.params import Depends
from sqlalchemy.orm import Session

from database.db import get_db
from models.category import Category
from models.category_level import CategoryLevel
from models.sub_category import SubCategory
from schemas.Category import CategoryResponse, CategoryLevelResponse, SubCategoryResponse

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("/", response_model=list[CategoryResponse])
def get_categories(db: Session = Depends(get_db)):
    """List all categories"""
    return db.query(Category).all()


@router.get("/levels", response_model=list[CategoryLevelResponse])
def get_category_levels(db: Session = Depends(get_db)):
    """List all category levels (includes TTL)"""
    return db.query(CategoryLevel).all()


@router.get("/{cat_id}/sub-categories", response_model=list[SubCategoryResponse])
def get_sub_categories(cat_id: int, db: Session = Depends(get_db)):
    """List sub categories for a specific category"""
    category = db.query(Category).filter(Category.cat_id == cat_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    return db.query(SubCategory).filter(SubCategory.cat_id == cat_id).all()


@router.get("/sub-categories", response_model=list[SubCategoryResponse])
def get_all_sub_categories(db: Session = Depends(get_db)):
    """List all sub categories"""
    return db.query(SubCategory).all()
