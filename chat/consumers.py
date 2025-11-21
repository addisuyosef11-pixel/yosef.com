import json
from channels.generic.websocket import AsyncWebsocketConsumer

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_group_name = "public_chat"
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        await self.accept()
        print("✅ WebSocket connected:", self.channel_name)

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
        print("❌ WebSocket disconnected:", close_code)

    async def receive(self, text_data):
        print("📩 Message received:", text_data)
        data = json.loads(text_data)
        message = data["message"]
        sender = data.get("sender", "Anonymous")

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "chat_message",
                "message": message,
                "sender": sender,
            }
        )

    async def chat_message(self, event):
        print("📤 Broadcasting:", event)
        await self.send(text_data=json.dumps({
            "message": event["message"],
            "sender": event["sender"],
        }))

