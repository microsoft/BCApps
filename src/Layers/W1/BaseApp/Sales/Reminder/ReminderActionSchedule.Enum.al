// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Defines the scheduling frequency options for automated reminder action groups.
/// </summary>
enum 6753 "Reminder Action Schedule"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Specifies that reminder actions are triggered manually by the user.
    /// </summary>
    value(0; "Manual") { Caption = 'Manual'; }
    /// <summary>
    /// Specifies that reminder actions are scheduled to run on a weekly basis.
    /// </summary>
    value(1; "Weekly") { Caption = 'Weekly'; }
    /// <summary>
    /// Specifies that reminder actions are scheduled to run on a monthly basis.
    /// </summary>
    value(2; "Monthly") { Caption = 'Monthly'; }
    /// <summary>
    /// Specifies that reminder actions follow a user-defined custom schedule.
    /// </summary>
    value(3; "Custom schedule") { Caption = 'Custom schedule'; }
}
