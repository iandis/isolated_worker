'use strict'
/**
 * 
 * @param {number} id 
 * @param {function(*):*} callback 
 */
function CallbackObject(id, callback) {
    this.id = id;
    this.callback = callback;
    return this;
}
/**
 * 
 * @param {number} id
 * @param {function(*):*} callback
 * @param {*} message 
 */
function CallbackMessage(id, callback, message) {
    this.prototype.id = id;
    this.prototype.callback = callback;
    this.message = message;
    return this;
}
Object.setPrototypeOf(CallbackMessage.prototype, CallbackObject);

/**
 * 
 * @param {number} id
 * @param {function(*):*} callback
 * @param {*} result 
 */
function ResultMessage(id, callback, result) {
    this.prototype.id = id;
    this.prototype.callback = callback;
    this.result = result;
    return this;
}
Object.setPrototypeOf(ResultMessage.prototype, CallbackObject);

/**
 * 
 * @param {number} id
 * @param {function(*):*} callback
 * @param {*} error 
 */
function ResultErrorMessage(id, callback, error) {
    this.prototype.id = id;
    this.prototype.callback = callback;
    this.error = error;
    return this;
}
Object.setPrototypeOf(ResultErrorMessage.prototype, CallbackObject);
