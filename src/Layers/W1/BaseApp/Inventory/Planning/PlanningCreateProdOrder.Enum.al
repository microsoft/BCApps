// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

enum 5526 "Planning Create Prod. Order"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Planned") { Caption = 'Planned'; }
    value(2; "Firm Planned") { Caption = 'Firm Planned'; }
    value(3; "Firm Planned & Print") { Caption = 'Firm Planned & Print'; }
    value(4; "Copy to Req. Wksh") { Caption = 'Copy to Req. Wksh'; }
}
