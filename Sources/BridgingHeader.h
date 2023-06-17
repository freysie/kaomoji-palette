@import Foundation;

NS_INLINE NSException * _Nullable tryBlock(NS_NOESCAPE void(^_Nonnull block)(void)) {
  @try {
    block();
  }
  @catch (NSException *exception) {
    return exception;
  }
  return nil;
}
