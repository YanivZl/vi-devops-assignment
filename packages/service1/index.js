const {MongoClient} = require("mongodb");
const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");

const app = express();
const port = process.env.PORT || 3000;
const url = process.env.MONGODB_URL;
const dbName = "DevOpsAssignment";


app.use(cors());
app.use(bodyParser.json());

async function connectToDatabase() {
    if (!url) {
        throw new Error("MONGODB_URL environment variable is not set");
    }
    const client = new MongoClient(url, {useNewUrlParser: true, useUnifiedTopology: true}); // Use new URL parser and unified topology for MongoClient
    await client.connect();
    console.log("Connected to MongoDB");

    const db = client.db(dbName);
    return {
        counterCollection: db.collection("counters"),
        orderCollection: db.collection("orders"),
    };
}

async function main() {
    const {counterCollection, orderCollection} = await connectToDatabase();

    app.get("/liveness", async (req, res) => {
        res.send("Service is alive");
    });

    app.delete("/orders/:id", async (req, res) => {
        await orderCollection.deleteOne({_id: Number(req.params.id)});
        res.send(`Order number ${req.params.id} deleted successfully.`);
    });

    app.post("/orders", async (req, res) => {
        const orderSeq = await counterCollection.findOneAndUpdate(
            {_id: "orderSeq"},
            {$inc: {seq: 1}},
            {upsert: true, returnOriginal: false} // Returns the document after update
        );

        await orderCollection.insertOne({
            _id: orderSeq.seq,
        });

        res.send(`Order number ${orderSeq.seq} created successfully.`);
    });

    app.listen(port, () => {
        console.log(`DevOps assignment service1 app listening on port ${port}`);
    });
}

main().catch(err => console.error("Failed to start the server:", err));
