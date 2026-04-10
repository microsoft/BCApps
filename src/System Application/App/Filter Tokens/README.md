This module enhances filtering by enabling users to enter additional filter tokens. 
The Code or Text filters accept the %me, %user, and %company filter tokens. 

The Date, Time, and DateTime filters accept the %today, %workdate, %yesterday, %tomorrow, %week, %month, %quarter filter tokens. 

In addition, the Date filters support date formulas. 
You can add more filter tokens by subscribing to the following events:
- `OnResolveDateFilterToken`
- `OnResolveTextFilterToken`
- `OnResolveTimeFilterToken`
- `OnResolveDateTokenFromDateTimeFilter`
- `OnResolveTimeTokenFromDateTimeFilter`


