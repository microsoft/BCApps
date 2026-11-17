// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

enum 30180 "Shpfy Mapping Execution Mode"
{
    Access = Internal;
    Extensible = false;

    value(0; Unspecified)
    {
        Caption = 'Unspecified', Locked = true;
    }
    value(1; Automatic)
    {
        Caption = 'Automatic', Locked = true;
    }
    value(2; FindMappings)
    {
        Caption = 'FindMappings', Locked = true;
    }
    value(3; Mapping)
    {
        Caption = 'Mapping', Locked = true;
    }
    value(4; Background)
    {
        Caption = 'Background', Locked = true;
    }
    value(5; Manual)
    {
        Caption = 'Manual', Locked = true;
    }
}
