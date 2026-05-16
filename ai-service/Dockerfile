FROM python:3.9-slim

# Cập nhật và cài đặt thư viện với các tham số tối ưu cho Docker
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements trước để tận dụng Docker Cache (giúp build nhanh hơn ở các lần sau)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Đảm bảo lệnh khởi chạy đúng với cấu trúc của bạn
CMD ["python", "main.py"]