from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.orm import declarative_base
#from sqlalchemy.ext.declarative import declarative_base
from .config import DATABASE_URL
#DATABASE_URL = "postgresql://neondb_owner:npg_ebcu3YV2xriP@ep-small-grass-ahwxqpfd-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require"

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

Base = declarative_base()

def get_db():
    db = SessionLocal()

    try:
        yield db

    finally:
        db.close()