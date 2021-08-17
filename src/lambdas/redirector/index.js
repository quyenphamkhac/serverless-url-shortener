const DynamoDB = require("aws-sdk/clients/dynamodb");
const ddb = new DynamoDB.DocumentClient({
  region: "ap-southeast-1",
});

const TABLE_NAME = process.env.TABLE_NAME;
exports.handler = async (event, context, callback) => {
  try {
    console.log("Received event: ", event);
    const { key } = event.pathParameters;
    const resp = await ddb
      .get({
        TableName: TABLE_NAME,
        Key: {
          Id: key,
        },
      })
      .promise();
    if (!resp.Item) {
      callback(null, {
        statusCode: 404,
        headers: {
          "Access-Control-Allow-Origin": "*",
        },
        body: {
          message: "Url Not Found",
        },
      });
    }
    const { OriginalUrl } = resp.Item;
    const data = {
      statusCode: 302,
      headers: {
        "Access-Control-Allow-Origin": "*",
        Location: OriginalUrl,
      },
    };
    callback(null, data);
  } catch (error) {
    callback(error);
  }
};
