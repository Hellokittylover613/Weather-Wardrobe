import os
import uuid
import json
import requests

from dotenv import load_dotenv
from google import genai

from fastapi import (
    FastAPI,
    Depends,
    HTTPException,
    UploadFile,
    File,
)

from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from sqlalchemy.orm import Session
from passlib.context import CryptContext

from database import engine, get_db
import models

from schemas import (
    UserCreate,
    UserLogin,
    FirebaseUserSync,
    WardrobeItemCreate,
    WardrobeItemUpdate,
)


# ============================================================
# ENVIRONMENT VARIABLES
# ============================================================

load_dotenv()

REMOVE_BG_API_KEY = os.getenv("REMOVE_BG_API_KEY")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

gemini_client = None

if GEMINI_API_KEY:
    gemini_client = genai.Client(
        api_key=GEMINI_API_KEY
    )


# ============================================================
# APP SETUP
# ============================================================

app = FastAPI(
    title="Weather Wardrobe API",
    version="1.0.0",
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# UPLOADS FOLDER
# ============================================================

BASE_DIR = os.path.dirname(
    os.path.abspath(__file__)
)

UPLOAD_DIR = os.path.join(
    BASE_DIR,
    "uploads",
)

os.makedirs(
    UPLOAD_DIR,
    exist_ok=True,
)

app.mount(
    "/uploads",
    StaticFiles(directory=UPLOAD_DIR),
    name="uploads",
)


# ============================================================
# PASSWORD HASHING
# ============================================================

pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
)


# ============================================================
# BASIC TEST ENDPOINTS
# ============================================================

@app.get("/")
def root():
    return {
        "status": "success",
        "message": "Weather Wardrobe API is running!",
    }


@app.get("/test")
def test():
    return {
        "status": "success",
        "message": "FastAPI is connected!",
    }


@app.get("/db-test")
def database_test():

    try:

        with engine.connect():

            return {
                "status": "success",
                "message": "FastAPI is connected to MySQL!",
            }

    except Exception as e:

        return {
            "status": "error",
            "message": str(e),
        }


# ============================================================
# USER REGISTRATION
# ============================================================

@app.post("/users")
def create_user(
    user: UserCreate,
    db: Session = Depends(get_db),
):

    existing_user = (
        db.query(models.User)
        .filter(
            models.User.email == user.email
        )
        .first()
    )

    if existing_user:

        raise HTTPException(
            status_code=400,
            detail="An account with this email already exists.",
        )

    if len(user.password) < 6:

        raise HTTPException(
            status_code=400,
            detail="Password must be at least 6 characters long.",
        )

    hashed_password = pwd_context.hash(
        user.password
    )

    new_user = models.User(
        name=user.name,
        email=user.email,
        password_hash=hashed_password,
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return {
        "status": "success",
        "message": "User created!",
        "user_id": new_user.id,
        "name": new_user.name,
        "email": new_user.email,
    }


# ============================================================
# LOGIN
# ============================================================

@app.post("/login")
def login(
    user: UserLogin,
    db: Session = Depends(get_db),
):

    existing_user = (
        db.query(models.User)
        .filter(
            models.User.email == user.email
        )
        .first()
    )

    if not existing_user:

        raise HTTPException(
            status_code=401,
            detail="Invalid email or password.",
        )

    if not pwd_context.verify(
        user.password,
        existing_user.password_hash,
    ):

        raise HTTPException(
            status_code=401,
            detail="Invalid email or password.",
        )

    return {
        "status": "success",
        "message": "Login successful!",
        "user_id": existing_user.id,
        "name": existing_user.name,
        "email": existing_user.email,
    }


# ============================================================
# FIREBASE USER SYNC
# ============================================================

@app.post("/firebase-users")
def sync_firebase_user(
    user: FirebaseUserSync,
    db: Session = Depends(get_db),
):

    # --------------------------------------------------------
    # Check Firebase UID
    # --------------------------------------------------------

    existing_user = (
        db.query(models.User)
        .filter(
            models.User.firebase_uid
            == user.firebase_uid
        )
        .first()
    )

    if existing_user:

        return {
            "status": "success",
            "message": "Firebase user already linked.",
            "user_id": existing_user.id,
            "firebase_uid": existing_user.firebase_uid,
            "name": existing_user.name,
            "email": existing_user.email,
        }

    # --------------------------------------------------------
    # Check email
    # --------------------------------------------------------

    existing_email = (
        db.query(models.User)
        .filter(
            models.User.email == user.email
        )
        .first()
    )

    if existing_email:

        existing_email.firebase_uid = (
            user.firebase_uid
        )

        db.commit()
        db.refresh(existing_email)

        return {
            "status": "success",
            "message": "Firebase user linked to existing account.",
            "user_id": existing_email.id,
            "firebase_uid": existing_email.firebase_uid,
            "name": existing_email.name,
            "email": existing_email.email,
        }

    # --------------------------------------------------------
    # Create new Firebase user
    # --------------------------------------------------------

    new_user = models.User(
        name=user.name or "User",
        email=user.email,
        password_hash="firebase_user",
        firebase_uid=user.firebase_uid,
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return {
        "status": "success",
        "message": "Firebase user created and linked.",
        "user_id": new_user.id,
        "firebase_uid": new_user.firebase_uid,
        "name": new_user.name,
        "email": new_user.email,
    }


# ============================================================
# UPLOAD IMAGE
# ============================================================

@app.post("/upload-image")
async def upload_image(
    image: UploadFile = File(...),
):

    try:

        # ----------------------------------------------------
        # Validate filename
        # ----------------------------------------------------

        if not image.filename:

            raise HTTPException(
                status_code=400,
                detail="No image filename was provided.",
            )

        # ----------------------------------------------------
        # Validate extension
        # ----------------------------------------------------

        allowed_extensions = {
            ".jpg",
            ".jpeg",
            ".png",
            ".webp",
            ".gif",
        }

        extension = os.path.splitext(
            image.filename
        )[1].lower()

        if extension not in allowed_extensions:

            raise HTTPException(
                status_code=400,
                detail=(
                    f"Unsupported image type: {extension}. "
                    "Please select JPG, JPEG, PNG, WEBP, or GIF."
                ),
            )

        # ----------------------------------------------------
        # Read image
        # ----------------------------------------------------

        image_data = await image.read()

        if not image_data:

            raise HTTPException(
                status_code=400,
                detail="The uploaded image is empty.",
            )

        # ----------------------------------------------------
        # Generate unique filename
        # ----------------------------------------------------

        unique_filename = (
            f"{uuid.uuid4()}{extension}"
        )

        file_path = os.path.join(
            UPLOAD_DIR,
            unique_filename,
        )

        # ----------------------------------------------------
        # Save image
        # ----------------------------------------------------

        with open(
            file_path,
            "wb",
        ) as file:

            file.write(image_data)

        # ----------------------------------------------------
        # Verify file
        # ----------------------------------------------------

        if not os.path.exists(file_path):

            raise HTTPException(
                status_code=500,
                detail="Image was not saved to the uploads folder.",
            )

        file_size = os.path.getsize(
            file_path
        )

        if file_size == 0:

            raise HTTPException(
                status_code=500,
                detail="Uploaded image file is empty.",
            )

        return {
            "status": "success",
            "message": "Image uploaded successfully!",
            "filename": unique_filename,
            "image_url": f"/uploads/{unique_filename}",
            "size": file_size,
        }

    except HTTPException:

        raise

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=f"Image upload failed: {str(e)}",
        )


# ============================================================
# REMOVE IMAGE BACKGROUND
# ============================================================

@app.post("/remove-background")
async def remove_background(
    filename: str,
):

    try:

        # ----------------------------------------------------
        # Check API key
        # ----------------------------------------------------

        if not REMOVE_BG_API_KEY:

            raise HTTPException(
                status_code=500,
                detail=(
                    "REMOVE_BG_API_KEY is missing from environment variables."
                ),
            )

        # ----------------------------------------------------
        # Security: only filename
        # ----------------------------------------------------

        safe_filename = os.path.basename(
            filename
        )

        input_path = os.path.join(
            UPLOAD_DIR,
            safe_filename,
        )

        # ----------------------------------------------------
        # Check original image
        # ----------------------------------------------------

        if not os.path.exists(input_path):

            raise HTTPException(
                status_code=404,
                detail="Uploaded image was not found.",
            )

        # ----------------------------------------------------
        # Output filename
        # ----------------------------------------------------

        output_filename = (
            f"removed_"
            f"{os.path.splitext(safe_filename)[0]}"
            f".png"
        )

        output_path = os.path.join(
            UPLOAD_DIR,
            output_filename,
        )

        # ----------------------------------------------------
        # Send image to Remove.bg
        # ----------------------------------------------------

        with open(
            input_path,
            "rb",
        ) as image_file:

            response = requests.post(
                "https://api.remove.bg/v1.0/removebg",
                files={
                    "image_file": image_file,
                },
                data={
                    "size": "auto",
                },
                headers={
                    "X-Api-Key": REMOVE_BG_API_KEY,
                },
                timeout=120,
            )

        # ----------------------------------------------------
        # Check Remove.bg response
        # ----------------------------------------------------

        if response.status_code != 200:

            raise HTTPException(
                status_code=500,
                detail=(
                    "Background removal failed: "
                    f"{response.text}"
                ),
            )

        # ----------------------------------------------------
        # Save processed PNG
        # ----------------------------------------------------

        with open(
            output_path,
            "wb",
        ) as output_file:

            output_file.write(
                response.content
            )

        # ----------------------------------------------------
        # Verify processed file
        # ----------------------------------------------------

        if not os.path.exists(output_path):

            raise HTTPException(
                status_code=500,
                detail="Processed image was not saved.",
            )

        return {
            "status": "success",
            "message": "Background removed successfully!",
            "original_filename": safe_filename,
            "processed_filename": output_filename,
            "image_url": f"/uploads/{output_filename}",
        }

    except HTTPException:

        raise

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=f"Background removal failed: {str(e)}",
        )


# ============================================================
# CREATE WARDROBE ITEM
# ============================================================

@app.post("/wardrobe-items")
def create_wardrobe_item(
    item: WardrobeItemCreate,
    db: Session = Depends(get_db),
):

    # --------------------------------------------------------
    # Verify user
    # --------------------------------------------------------

    user = (
        db.query(models.User)
        .filter(
            models.User.id == item.user_id
        )
        .first()
    )

    if not user:

        raise HTTPException(
            status_code=404,
            detail="User not found.",
        )

    # --------------------------------------------------------
    # Create wardrobe item
    # --------------------------------------------------------

    new_item = models.WardrobeItem(
        user_id=item.user_id,
        name=item.name,
        category=item.category,
        color=item.color,
        weather=item.weather,
        occasion=item.occasion,
        image_url=item.image_url,
    )

    db.add(new_item)
    db.commit()
    db.refresh(new_item)

    return {
        "status": "success",
        "message": "Wardrobe item created!",
        "item": {
            "id": new_item.id,
            "user_id": new_item.user_id,
            "name": new_item.name,
            "category": new_item.category,
            "color": new_item.color,
            "weather": new_item.weather,
            "occasion": new_item.occasion,
            "image_url": new_item.image_url,
        },
    }


# ============================================================
# GET CURRENT USER'S WARDROBE
# ============================================================

@app.get("/wardrobe-items")
def get_wardrobe_items(
    user_id: int,
    db: Session = Depends(get_db),
):

    items = (
        db.query(models.WardrobeItem)
        .filter(
            models.WardrobeItem.user_id == user_id
        )
        .all()
    )

    return {
        "status": "success",
        "items": [
            {
                "id": item.id,
                "user_id": item.user_id,
                "name": item.name,
                "category": item.category,
                "color": item.color,
                "weather": item.weather,
                "occasion": item.occasion,
                "image_url": item.image_url,
            }
            for item in items
        ],
    }


# ============================================================
# UPDATE WARDROBE ITEM
# ============================================================

@app.put("/wardrobe-items/{item_id}")
def update_wardrobe_item(
    item_id: int,
    item: WardrobeItemUpdate,
    db: Session = Depends(get_db),
):

    wardrobe_item = (
        db.query(models.WardrobeItem)
        .filter(
            models.WardrobeItem.id == item_id
        )
        .first()
    )

    if not wardrobe_item:

        raise HTTPException(
            status_code=404,
            detail="Wardrobe item not found.",
        )

    if item.name is not None:
        wardrobe_item.name = item.name

    if item.category is not None:
        wardrobe_item.category = item.category

    if item.color is not None:
        wardrobe_item.color = item.color

    if item.weather is not None:
        wardrobe_item.weather = item.weather

    if item.occasion is not None:
        wardrobe_item.occasion = item.occasion

    if item.image_url is not None:
        wardrobe_item.image_url = item.image_url

    db.commit()
    db.refresh(wardrobe_item)

    return {
        "status": "success",
        "message": "Wardrobe item updated!",
        "item": {
            "id": wardrobe_item.id,
            "user_id": wardrobe_item.user_id,
            "name": wardrobe_item.name,
            "category": wardrobe_item.category,
            "color": wardrobe_item.color,
            "weather": wardrobe_item.weather,
            "occasion": wardrobe_item.occasion,
            "image_url": wardrobe_item.image_url,
        },
    }


# ============================================================
# DELETE WARDROBE ITEM
# ============================================================

@app.delete("/wardrobe-items/{item_id}")
def delete_wardrobe_item(
    item_id: int,
    db: Session = Depends(get_db),
):

    wardrobe_item = (
        db.query(models.WardrobeItem)
        .filter(
            models.WardrobeItem.id == item_id
        )
        .first()
    )

    if not wardrobe_item:

        raise HTTPException(
            status_code=404,
            detail="Wardrobe item not found.",
        )

    db.delete(wardrobe_item)
    db.commit()

    return {
        "status": "success",
        "message": "Wardrobe item deleted!",
    }


# ============================================================
# AI OUTFIT SUGGESTION - GEMINI
# ============================================================

@app.post("/outfit-suggestion")
def get_outfit_suggestion(
    payload: dict,
    db: Session = Depends(get_db),
):

    try:

        # ----------------------------------------------------
        # Validate Gemini API key
        # ----------------------------------------------------

        if not GEMINI_API_KEY:

            raise HTTPException(
                status_code=500,
                detail="GEMINI_API_KEY is missing from environment variables.",
            )

        # ----------------------------------------------------
        # Get request data
        # ----------------------------------------------------

        user_id = payload.get("user_id")
        temperature = payload.get("temperature")
        condition = payload.get("condition")
        occasion = payload.get(
            "occasion",
            "Any",
        )

        if (
            user_id is None
            or temperature is None
            or condition is None
        ):

            raise HTTPException(
                status_code=400,
                detail=(
                    "user_id, temperature, and condition "
                    "are required."
                ),
            )

        # ----------------------------------------------------
        # Fetch user's wardrobe
        # ----------------------------------------------------

        items = (
            db.query(models.WardrobeItem)
            .filter(
                models.WardrobeItem.user_id
                == user_id
            )
            .all()
        )

        if not items:

            return {
                "status": "success",
                "suggestion": (
                    "Your wardrobe is empty. Add some clothing "
                    "items first and I'll help you choose an outfit!"
                ),
                "recommended_item_ids": [],
            }

        # ----------------------------------------------------
        # Prepare wardrobe information
        # ----------------------------------------------------

        wardrobe_summary = [
            {
                "id": item.id,
                "name": item.name,
                "category": item.category,
                "weather": item.weather,
                "occasion": item.occasion,
            }
            for item in items
        ]

        # ----------------------------------------------------
        # Build Gemini prompt
        # ----------------------------------------------------

        prompt = (
            "You are the AI fashion assistant inside a "
            "Weather Wardrobe app.\n\n"

            "Your job is to recommend ONE outfit using ONLY "
            "items that actually exist in the user's wardrobe.\n\n"

            f"Current temperature: {temperature}°C\n"
            f"Current weather: {condition}\n"
            f"Occasion: {occasion}\n\n"

            "User's wardrobe:\n"
            f"{json.dumps(wardrobe_summary, indent=2)}\n\n"

            "Choose a practical outfit that matches the "
            "weather and occasion. "

            "Prefer a combination of a top, bottom, and shoes "
            "when available. "

            "Add outerwear or accessories only when appropriate.\n\n"

            "IMPORTANT:\n"
            "- Only recommend items from the wardrobe provided above.\n"
            "- Use the exact item IDs from the wardrobe.\n"
            "- Do not invent clothing items.\n"
            "- Keep the explanation friendly and concise.\n\n"

            "Return ONLY valid JSON in exactly this format:\n"

            "{\n"
            '  "suggestion": "A short friendly explanation",\n'
            '  "recommended_item_ids": [1, 2, 3]\n'
            "}"
        )

        # ----------------------------------------------------
        # Call Gemini API
        # ----------------------------------------------------

        gemini_url = (
            "https://generativelanguage.googleapis.com/"
            "v1beta/models/gemini-3.7-flash:generateContent"
        )

        response = requests.post(
            gemini_url,
            headers={
                "x-goog-api-key": GEMINI_API_KEY,
                "Content-Type": "application/json",
            },
            json={
                "contents": [
                    {
                        "parts": [
                            {
                                "text": prompt
                            }
                        ]
                    }
                ],
                "generationConfig": {
                    "temperature": 0.7,
                    "maxOutputTokens": 300,
                    "responseMimeType": "application/json",
                },
            },
            timeout=30,
        )

        # ----------------------------------------------------
        # Check Gemini response
        # ----------------------------------------------------

        if response.status_code != 200:

            raise HTTPException(
                status_code=500,
                detail=(
                    "Gemini request failed: "
                    f"{response.text}"
                ),
            )

        result = response.json()

        # ----------------------------------------------------
        # Extract Gemini text
        # ----------------------------------------------------

        try:

            ai_text = (
                result["candidates"][0]
                ["content"]["parts"][0]["text"]
            )

        except (
            KeyError,
            IndexError,
            TypeError,
        ):

            raise HTTPException(
                status_code=500,
                detail=(
                    "Unexpected Gemini response: "
                    f"{response.text}"
                ),
            )

        # ----------------------------------------------------
        # Parse Gemini JSON
        # ----------------------------------------------------

        try:

            parsed = json.loads(ai_text)

            suggestion_text = parsed.get(
                "suggestion",
                "I found an outfit for you!",
            )

            recommended_ids = parsed.get(
                "recommended_item_ids",
                [],
            )

        except json.JSONDecodeError:

            suggestion_text = ai_text
            recommended_ids = []

        # ----------------------------------------------------
        # Make sure recommended IDs are valid
        # ----------------------------------------------------

        valid_item_ids = {
            item.id
            for item in items
        }

        recommended_ids = [
            item_id
            for item_id in recommended_ids
            if item_id in valid_item_ids
        ]

        # ----------------------------------------------------
        # Return result
        # ----------------------------------------------------

        return {
            "status": "success",
            "suggestion": suggestion_text,
            "recommended_item_ids": recommended_ids,
        }

    except HTTPException:

        raise

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=(
                f"Outfit suggestion failed: {str(e)}"
            ),
        )