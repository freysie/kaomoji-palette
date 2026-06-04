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

@import AppKit;

typedef NS_ENUM(NSInteger, NSScrollPocketStyle) {
  NSScrollPocketStyleAutomatic,
  NSScrollPocketStyleSoft,
  NSScrollPocketStyleHard,
};

typedef NS_ENUM(NSInteger, NSScrollPocketEdge) {
  NSScrollPocketEdgeTop    = 0,
  NSScrollPocketEdgeBottom = 1,
  NSScrollPocketEdgeLeft   = 2,
  NSScrollPocketEdgeRight  = 3,
};

typedef NS_OPTIONS(NSInteger, NSScrollPocketEdges) {
  NSScrollPocketEdgesTop    = 1 << NSScrollPocketEdgeTop,
  NSScrollPocketEdgesBottom = 1 << NSScrollPocketEdgeBottom,
  NSScrollPocketEdgesLeft   = 1 << NSScrollPocketEdgeLeft,
  NSScrollPocketEdgesRight  = 1 << NSScrollPocketEdgeRight,
};

@interface NSScrollPocket : NSView
- (void)addElementContainer:(NSView *)elementContainer;
- (void)removeElementContainer:(NSView *)elementContainer;
@property (nonatomic) BOOL prefersSolidColorHardPocket;
@property NSScrollPocketEdge edge;
@property NSScrollPocketStyle style;
@property (copy, nullable) NSColor *captureColor;
@property (readonly, strong) NSView *captureView;
@end

@interface NSScrollView (ScrollPocketSPI)
@property NSScrollPocketEdges alwaysShownPocketEdges;
@property NSScrollPocketEdges allowedPocketEdges;
- (void)registerPocketContainer:(NSView *)container onEdge:(NSScrollPocketEdge)edge;
- (void)unregisterPocketContainer:(NSView *)container onEdge:(NSScrollPocketEdge)edge;
- (NSScrollPocketStyle)scrollPocketStyleOnEdge:(NSScrollPocketEdge)edge;
- (void)setScrollPocketStyle:(NSScrollPocketStyle)style onEdge:(NSScrollPocketEdge)edge;
@end
