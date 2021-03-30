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
/**
* @description Used to mock invalid elevate capture group requests for unit tests
 */
public class ElevateCaptureGroupInvalidRequest extends ElevateCaptureGroup {

    public static final String INVALID_PARAMETER = 'invalid-parameter';
    public static final String INVALID_GROUP_ID = 'invalid-group-id';
    private static final String DUMMY_GROUP_ID = 'gp-12345';

    private String groupId;
    private String requestBody;

    @TestVisible
    private PS_Request.Builder requestBuilder {
        get {
            if (requestBuilder == null) {
                requestBuilder = new PS_Request.Builder();
            }
            return requestBuilder;
        }
        set;
    }

    @TestVisible
    private ElevateTokenizedGift tokenizedGift {
        get {
            if (tokenizedGift == null) {
                tokenizedGift = new ElevateTokenizedGift();
            }
            return tokenizedGift;
        }
        set;
    }

    public ElevateCaptureGroupInvalidRequest withInvalidGroupId() {
        groupId = INVALID_GROUP_ID;
        return this;
    }

    public ElevateCaptureGroupInvalidRequest withInvalidRequestBody() {
        requestBody = '{"merchantId":\"' + INVALID_PARAMETER + '\"}';
        return this;
    }

    protected override HttpRequest createRequest() {
        System.debug(requestBody);
        return requestBuilder.withMethod(UTIL_Http.Method.POST)
                             .withEndpoint(PS_Request.ElevateEndpoint.CREATE_CAPTURE_GROUP)
                             .withBody(requestBody)
                             .build();
    }

    protected override HttpRequest addRequest(ElevateTokenizedGift tokenizedGift, String invalidGroupId) {
        return requestBuilder.withMethod(UTIL_Http.Method.POST)
                             .withCaptureGroupId(invalidGroupId)
                             .withEndpoint(PS_Request.ElevateEndpoint.ADD_TO_CAPTURE_GROUP)
                             .withBody(JSON.serialize(tokenizedGift))
                             .build();
    }

    public override String groupId() {
        if (String.isBlank(groupId)) {
            return DUMMY_GROUP_ID;
        } else {
            return groupId;
        }
    }
}