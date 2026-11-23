// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

pageextension 12106 "Business Activities IT" extends "Business Activities"
{
    trigger OnOpenPage()
    var
        BusinessActivityFeature: Codeunit "Business Activity Feature IT";
    begin
        if not BusinessActivityFeature.IsEnabled() then
            Error(EnableFeatureErr);
    end;

    var
        EnableFeatureErr: Label 'Enable the Business Activity Code feature in Feature Management and complete the data update before using business activity codes in Italy.';
}
