// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

enum 800 "Docs - Retention Period Def." implements "Documents - Retention Period"
{
    Extensible = true;
    value(0; Default)
    {
        Caption = 'Default';
        Implementation = "Documents - Retention Period" = "Default Retention Period Def.";
    }
}