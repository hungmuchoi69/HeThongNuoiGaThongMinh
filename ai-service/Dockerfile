FROM python:3.9-slim

WORKDIR /app

# Copy requirements trước để tận dụng Docker Cache (giúp build nhanh hơn ở các lần sau)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Đảm bảo lệnh khởi chạy đúng với cấu trúc của bạn
CMD ["python", "main.py"]