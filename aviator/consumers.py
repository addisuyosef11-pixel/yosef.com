from channels.generic.websocket import AsyncWebsocketConsumer
import json, asyncio, random

class AviatorConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        await self.accept()
        await self.send(json.dumps({"message": "connected"}))

    async def receive(self, text_data):
        data = json.loads(text_data)
        if data.get("action") == "start":
            await self.start_game()

    async def start_game(self):
        multiplier = 1.00
        crash_point = round(random.uniform(1.1, 10.0), 2)

        while multiplier < crash_point:
            await self.send(json.dumps({"multiplier": round(multiplier, 2)}))
            multiplier += 0.05
            await asyncio.sleep(0.1)

        await self.send(json.dumps({"crash": crash_point}))
