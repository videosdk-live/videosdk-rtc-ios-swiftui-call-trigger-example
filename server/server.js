const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const morgan = require("morgan");
var Key = "./AuthKey_YOUR_KEY_ID.p8"; // TODO: Change File Name
var apn = require("apn");
const { v4: uuidv4 } = require("uuid");
const serviceAccount = require("./YOUR_SERVICE_ACCOUNT_KEY.json"); // Replace with the path to your service account key

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan("dev"));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

app.post("/initiate-call", (req, res) => {
  const { calleeInfo, callerInfo, videoSDKInfo } = req.body;

  let deviceToken = calleeInfo.deviceToken;

  var options = {
    token: {
      key: Key,
      keyId: "YOUR_KEY_ID",
      teamId: "YOUR_TEAM_ID",
    },
    production: false,
  };

  var apnProvider = new apn.Provider(options);

  var note = new apn.Notification();

  note.expiry = Math.floor(Date.now() / 1000) + 3600; // Expires 1 hour from now.

  note.badge = 1;
  note.sound = "ping.aiff";
  note.alert = "You have a new message";
  note.rawPayload = {
    callerName: callerInfo.name,
    aps: {
      "content-available": 1,
    },
    handle: callerInfo.name,
    callerInfo,
    videoSDKInfo,
    type: "CALL_INITIATED",
    uuid: uuidv4(),
  };
  note.pushType = "voip";
  note.topic = "com.videosdk.live.CallKitSwiftUI.voip";
  apnProvider.send(note, deviceToken).then((result) => {
    if (result.failed && result.failed.length > 0) {
      console.log("RESULT", result.failed[0].response);
      res.status(400).send(result.failed[0].response);
    } else {
      res.status(200).send(result);
    }
  });
});

app.post("/update-call", (req, res) => {
  const { callerInfo, type } = req.body;
  const { name, fcmToken } = callerInfo;

  const message = {
    notification: {
      title: name,
      body: "Hello VideoSDK",
    },
    data: {
      type,
    },
    token: fcmToken,
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  };

  admin
    .messaging()
    .send(message)
    .then((response) => {
      res.status(200).send(response);
      console.log("Successfully sent message:", response);
    })
    .catch((error) => {
      res.status(400).send(error);
      console.log("Error sending message:", error);
    });
});

// Start the server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}/`);
});
