from fastapi import FastAPI

from script import getPath

app = FastAPI()


@app.get("/")
async def root():
    return {"message": "Hi mom!"}


@app.get("/path/")
def path(city: str, start: str, end: str) -> list[list[float]]:
    return getPath(city, start, end)
