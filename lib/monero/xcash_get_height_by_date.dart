// X-Cash specific date-to-height conversion
// X-Cash blockchain started around late 2018 / early 2019
// Significant height 800000 was reached around February 2021

/// X-Cash launch date threshold for height calculation
/// Dates before Feb 1, 2021 should scan from height 0
/// Dates on or after Feb 1, 2021 should start from height 800000
final DateTime xcashHeightThresholdDate = DateTime(2021, 2, 1);
const int xcashMinimumRestoreHeight = 800000;

/// Get X-Cash blockchain height by date
/// 
/// Rules:
/// - If date is before February 1, 2021: return 0 (scan from genesis)
/// - If date is on or after February 1, 2021: return 800000
/// 
/// This is a simplified approach since X-Cash doesn't have the same
/// dense block height data as Monero for precise calculations.
int getXcashHeightByDate({DateTime date}) {
  if (date == null) {
    return 0;
  }
  
  if (date.isBefore(xcashHeightThresholdDate)) {
    return 0;
  }
  
  return xcashMinimumRestoreHeight;
}
