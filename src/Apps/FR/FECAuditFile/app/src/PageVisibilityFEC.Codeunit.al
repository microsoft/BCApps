// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

codeunit 10879 "Page Visibility FEC" implements "Audit File Export Page Visibility"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetUIVisibility(var FieldVisibility: Dictionary of [Text, Boolean]; var ActionVisibility: Dictionary of [Text, Boolean])
    begin
        // FEC format hides certain fields and actions from the base page
        FieldVisibility.Set('GLAccountMappingCode', false);
        FieldVisibility.Set('SplitByMonth', false);
        FieldVisibility.Set('SplitByDate', false);
        FieldVisibility.Set('HeaderComment', false);
        FieldVisibility.Set('Contact', false);
        FieldVisibility.Set('ZipFileGeneration', false);
        FieldVisibility.Set('CreateMultipleZipFiles', false);
        FieldVisibility.Set('LatestDataCheckDateTime', false);
        FieldVisibility.Set('DataCheckStatus', false);
        ActionVisibility.Set('DataCheck', false);
    end;
}
