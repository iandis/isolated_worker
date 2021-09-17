onmessage = async function (e) {
    const data = e.data;
    try {
        const result = await data.callback(data.message);
        const resultMessage = new ResultMessage(data.id, data.callback, result);
        postMessage(resultMessage);
    } catch (error) {
        const resultErrorMessage = new ResultErrorMessage(data.id, data.callback, error);
        postMessage(resultErrorMessage);
    }
}