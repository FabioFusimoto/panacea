import asyncio
import serial
import serial.tools.list_ports
import websockets

serialPort = serial.tools.list_ports.comports()[0].device
print('Starting serial connection to port {}...'.format(serialPort))
connection = serial.Serial(serialPort, 230400, timeout=1)

async def handler(websocket):
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
