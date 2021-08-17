const DynamoDB = require("aws-sdk/clients/dynamodb");
const ddb = new DynamoDB.DocumentClient({
  region: "ap-southeast-1",
});

const TABLE_NAME = process.env.TABLE_NAME;
const DAY_TO_SECS = 86400;

exports.handler = async (event, context, callback) => {
  try {
    console.log("Received event: ", event);
    const body = JSON.parse(event.body);
    const { url, daysTolive = 7 } = body;
    const shortId = generateRandom();
    await ddb
      .put({
        TableName: TABLE_NAME,
        Item: {
          Id: shortId,
          Ttl: timeEpoch() + daysTolive * DAY_TO_SECS,
          OriginalUrl: url,
          Timestamp: timeEpoch(),
        },
        ConditionExpression: "attribute_not_exists(Id)",
      })
      .promise();
    const data = {
      originalUrl: url,
      shortenUrl: `${event.requestContext.domainName}/${shortId}`,
    };
    callback(null, data);
  } catch (error) {
    callback(error);
  }
};

const generateRandom = (length = 7) => {
  let result = "";
  const characters = "abcdefghjkmnpqrstuvwxyz23456789";
  const charactersLength = characters.length;
  for (let i = 0; i < length; i++) {
    result += characters.charAt(Math.floor(Math.random() * charactersLength));
  }
  return result;
};

const timeEpoch = () => {
  return Math.round(new Date().getTime() / 1000);
};
