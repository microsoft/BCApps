// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

enum 5405 "Production Order Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Simulated") { Caption = 'Simulated'; }
    value(1; "Planned") { Caption = 'Planned'; }
    value(2; "Firm Planned") { Caption = 'Firm Planned'; }
    value(3; "Released") { Caption = 'Released'; }
    value(4; "Finished") { Caption = 'Finished'; }
}
