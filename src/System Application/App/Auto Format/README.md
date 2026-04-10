This module provides methods for formatting the appearance of decimal data types in fields on tables, reports, and pages.

Use this module to do the following:
- Format decimals for text messages in the same way that the system formats decimals in fields.
- Get the default rounding precision.

For on-premises versions, you can also use this module to personalize expressions for formatting data.

Remarks
This module introduces the following changes:
- The procedure AutoFormatTranslate has been renamed to ResolveAutoFormat.
- Enum type 59 Auto Format is new. 
- The parameter AutoFormatType: Enum Auto Format replaces the parameter AutoFormatType: Integer.
- The logic for cases other than 0 (Enum DefaultFormat) and 11 (Enum CustomFormatExpr) has been moved to Base Application but the behavior is unchanged.
- The publisher OnResolveAutoFormat has the scope OnPrem, but everyone can subscribe to it and implement a new logic for formatting decimal numbers in text messages.

