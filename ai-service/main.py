from fastapi import FastAPI, Request, BackgroundTasks
import uvicorn

app = FastAPI()

def process_ai(image_bytes, device_id):
    print(f"AI đang phân tích ảnh từ: {device_id}")
    # Sau này sẽ viết logic OpenCV ở đây

@app.post("/upload")
async def upload(request: Request, background_tasks: BackgroundTasks):
    device_id = request.headers.get("x-device-id", "unknown")
    body = await request.body()
    background_tasks.add_task(process_ai, body, device_id)
    return {"status": "success", "device": device_id}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)