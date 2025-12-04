// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

enum 7787 "AOAI Policy"
{
    Extensible = false;
    Access = Internal;

    /// <summary>
    /// Requests containing harms with a low severity are blocked and XPIA detection is enabled.
    /// </summary>
    value(1; "ConservativeWithXPIA")
    {
        Caption = 'ConservativeWithXPIA', Locked = true;
    }

    /// <summary>
    /// Requests containing harms with a low severity are blocked and XPIA detection is disabled.
    /// </summary>
    value(2; "ConservativeWithoutXPIA")
    {
        Caption = 'ConservativeWithoutXPIA', Locked = true;
    }

    /// <summary>
    /// Requests containing harms with a medium severity are blocked and XPIA detection is enabled.
    /// </summary>
    value(3; "MediumWithXPIA")
    {
        Caption = 'MediumWithXPIA', Locked = true;
    }

    /// <summary>
    /// Requests containing harms with a medium severity are blocked and XPIA detection is disabled.
    /// </summary>
    value(4; "MediumWithoutXPIA")
    {
        Caption = 'Default', Locked = true;
    }

}