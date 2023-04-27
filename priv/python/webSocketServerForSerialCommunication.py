import asyncio
import serial
import websockets

async def handler(websocket):
    print('Starting serial connection...')
    connection = serial.Serial('COM3', 230400, timeout=1)
    async for message in websocket:
        connection.write(bytes(message, 'ascii'))
        # Wait for ACK
        connection.read()

async def main():
    print('Starting server...')
    async with websockets.serve(handler, "", 8001):
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())