from pydantic import BaseModel, EmailStr
from typing import Optional


class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class FirebaseUserSync(BaseModel):
    firebase_uid: str
    email: EmailStr
    name: Optional[str] = None


class WardrobeItemCreate(BaseModel):
    user_id: int
    name: Optional[str] = None
    category: str
    color: Optional[str] = None
    weather: Optional[str] = None
    occasion: Optional[str] = None
    image_url: Optional[str] = None


class WardrobeItemUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    color: Optional[str] = None
    weather: Optional[str] = None
    occasion: Optional[str] = None
    image_url: Optional[str] = None