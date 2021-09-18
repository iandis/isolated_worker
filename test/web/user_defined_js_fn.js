/**
 * 
 * @param {string} url 
 * @returns {*}
 */
async function get(url) {
    const response = await fetch(url, {
        method: 'GET',
        mode: 'cors',
        headers: {
            'Accept': 'application/json',
        },
    });
    return await response.json();
}