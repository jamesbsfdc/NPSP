/*
 * Copyright (c) 2020, Salesforce.org
 *     All rights reserved.
 *
 *     Redistribution and use in source and binary forms, with or without
 *     modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Salesforce.org nor the names of
 *       its contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 *     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *     "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *     LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 *     FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *     COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *     INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 *     BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *     CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 *     LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 *     ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *     POSSIBILITY OF SUCH DAMAGE.
 */
@isTest
public with sharing class ElevateAuthorizedGift_TEST {

    private static final Decimal DUMMY_AMOUNT = 100.00;
    private static final String DUMMY_TOKEN = 'token-1234';
    private static final String DUMMY_LAST_NAME = 'Bond';
    private static final String DUMMY_FIRST_NAME = 'James';
    private static final String DUMMY_PAYMENT_TYPE = 'card';
    private static final String DUMMY_ID = 'id-123456789';
    private static final String DUMMY_STATUS = 'AUTHORIZED';

    @isTest
    private static void valueQueriesShouldReturnCorrectValues() {
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);
        ElevateAuthorizedGift authorizedGift;

        Test.startTest();
            authorizedGift = new ElevateAuthorizedGift(createTokenizedGift(),
                    createAuthorizedGiftResponse());
        Test.stopTest();

        System.assertEquals(DUMMY_AMOUNT, authorizedGift.tokenizedGift.amount());
        System.assertEquals(DUMMY_TOKEN, authorizedGift.tokenizedGift.token());
        System.assertEquals(DUMMY_LAST_NAME, authorizedGift.tokenizedGift.lastName());
        System.assertEquals(DUMMY_FIRST_NAME, authorizedGift.tokenizedGift.firstName());
        System.assertEquals(DUMMY_PAYMENT_TYPE, authorizedGift.paymentMethod());
        System.assertEquals(DUMMY_ID, authorizedGift.paymentId());
        System.assertEquals(DUMMY_ID, authorizedGift.gatewayTransactionId());
        System.assertEquals(DUMMY_ID, authorizedGift.originalTransactionId());
        System.assertEquals(DUMMY_ID, authorizedGift.groupId());
        System.assertEquals(System.today().addDays(1), authorizedGift.authExpiration());
        System.assertEquals(DUMMY_STATUS, authorizedGift.status());
    }

    private static ElevateTokenizedGift createTokenizedGift() {
        ElevateTokenizedGift tokenizedGift = new ElevateTokenizedGift();
        tokenizedGift.amount = DUMMY_AMOUNT;
        tokenizedGift.paymentMethodToken = DUMMY_TOKEN;
        tokenizedGift.lastName = DUMMY_LAST_NAME;
        tokenizedGift.firstName = DUMMY_FIRST_NAME;

        return tokenizedGift;
    }

    private static ElevateAuthorizedGiftResponse createAuthorizedGiftResponse() {
        ElevateAuthorizedGiftResponse authorizedGiftResponse = new ElevateAuthorizedGiftResponse();
        authorizedGiftResponse.body = new ElevateAuthorizedGiftResponse.Body();
        authorizedGiftResponse.body.id = DUMMY_ID;
        authorizedGiftResponse.body.authExpiresAt = System.today().addDays(1);
        authorizedGiftResponse.body.gatewayTransactionId = DUMMY_ID;
        authorizedGiftResponse.body.paymentType = DUMMY_PAYMENT_TYPE;
        authorizedGiftResponse.body.originalTransactionId = DUMMY_ID;
        authorizedGiftResponse.body.batchId = DUMMY_ID;
        authorizedGiftResponse.body.status = ElevateTransactionStatus.AUTHORIZED;
        return authorizedGiftResponse;
    }
}