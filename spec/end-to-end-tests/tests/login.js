var common = require('../common.js')


var test_logout = function(browser) {
  common.extended(browser)
    .url(process.env.APP_SERVER_URL)
    .waitForElementVisible('body', common.waitTimeout)
    .assert.containsText('h1', 'Publish and update data')
    .clickOnLink('Sign in')
    .pause(3000)
    .waitForElementVisible('main', common.waitTimeout)
    .assert.containsText('h1', 'Sign in')
    .clearSetValue('#user_email', process.env.USER_EMAIL)
    .clearSetValue('#user_password', process.env.USER_PASSWORD)
    .submitFormAndCheckNextTitle('Tasks')
    .clickOnLink('Sign out')
    .assert.containsText('h1', 'Publish and update data')
    .end();
};

var test_userpage = function(browser) {
  common.login(browser, process.env.USER_EMAIL, process.env.USER_PASSWORD)
    .click('a[href^="/accounts/user/"]')
    .waitForElementVisible('h1', common.waitTimeout)
    .assert.containsText('h1', 'Your account')
    .assert.containsText('ul.user-details', process.env.USER_EMAIL)
    .end()
};

module.exports = {
  'Successful login': test_login,
  'Successful logout': test_logout,
  'Failed login': test_failed_login,
  'User account page': test_userpage
}
