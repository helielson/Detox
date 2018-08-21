//
//  GREYMatchers+Detox.m
//  Detox
//
//  Created by Tal Kol on 10/7/16.
//  Copyright © 2016 Wix. All rights reserved.
//

#import "GREYMatchers+Detox.h"
#import "EarlGreyExtensions.h"
#import "ReactNativeSupport.h"

@implementation GREYMatchers (Detox)

+ (id<GREYMatcher>)detoxMatcherForText:(NSString *)text
{
	Class RCTTextViewClass = NSClassFromString(@"RCTText") ?: NSClassFromString(@"RCTTextView");
    if (!RCTTextViewClass)
    {
        return grey_text(text);
    }
    
    // in React Native RCTText the accessibilityLabel is hardwired to be the text inside
    return grey_anyOf(grey_text(text),
                      grey_allOf(grey_kindOfClass(RCTTextViewClass),
                                 hasProperty(@"accessibilityLabel", text),
								 nil),
					  nil);
    
}

//all(label, not_decendant(all(RCTText, with-label))

+ (id<GREYMatcher>)detox_matcherForAccessibilityLabel:(NSString *)label {
	if (![ReactNativeSupport isReactNativeApp])
	{
		return  [self matcherForAccessibilityLabel:label];
	}
	else
	{
		Class RCTTextViewClass = NSClassFromString(@"RCTText") ?: NSClassFromString(@"RCTTextView");
		return grey_allOf(grey_accessibilityLabel(label),
						  grey_not(grey_descendant(grey_allOf(grey_kindOfClass(RCTTextViewClass),
															  grey_accessibilityLabel(label),
															  nil))),
						  nil);
	}
	
}

id<GREYMatcher> detox_grey_kindOfClass(Class cls)
{
	MatchesBlock matches = ^BOOL(id element) {
		if(cls == UIScrollView.class && [element isKindOfClass:UIView.class] && [((UIView*)element).superview isKindOfClass:NSClassFromString(@"RCTScrollView")])
		{
			return YES;
		}
		
		return [element isKindOfClass:cls];
	};
	DescribeToBlock describe = ^void(id<GREYDescription> description) {
		[description appendText:[NSString stringWithFormat:@"detox_kindOfClass('%@')",
								 NSStringFromClass(cls)]];
	};
	return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
}

id<GREYMatcher> detox_grey_parent(id<GREYMatcher> ancestorMatcher)
{
	MatchesBlock matches = ^BOOL(id element) {
		id parent = nil;
		
		if ([element isKindOfClass:[UIView class]]) {
			parent = [element superview];
		} else {
			parent = [parent accessibilityContainer];
		}
		
		if (parent && [ancestorMatcher matches:parent]) {
			return YES;
		}
		
		return NO;
	};
	DescribeToBlock describe = ^void(id<GREYDescription> description) {
		[description appendText:[NSString stringWithFormat:@"parentThatMatches(%@)",
								 ancestorMatcher]];
	};
	return grey_allOf(grey_anyOf(grey_kindOfClass([UIView class]),
								 grey_respondsToSelector(@selector(accessibilityContainer)),
								 nil),
					  [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches
														   descriptionBlock:describe],
					  nil);
}

+ (id<GREYMatcher>)detoxMatcherForScrollChildOfMatcher:(id<GREYMatcher>)matcher
{
	return grey_anyOf(grey_allOf(
								   grey_anyOf(grey_kindOfClass([UIScrollView class]),
											  grey_kindOfClass([UIWebView class]),
											  grey_kindOfClass([UITextView class]),
											  nil),
								   matcher,
								   nil),
						grey_allOf(
								   grey_kindOfClass([UIScrollView class]),
								   detox_grey_parent(matcher),
								   nil),
						 nil);
}

+ (id<GREYMatcher>)detoxMatcherAvoidingProblematicReactNativeElements:(id<GREYMatcher>)matcher
{
	Class RN_RCTScrollView = NSClassFromString(@"RCTScrollView");
	if (!RN_RCTScrollView)
	{
		return matcher;
	}
	
	return grey_anyOf(
					  grey_allOf(grey_not(grey_kindOfClass(RN_RCTScrollView)),
								 matcher,
								 nil),
					  grey_allOf(detox_grey_parent(grey_kindOfClass(RN_RCTScrollView)),
								 detox_grey_parent(matcher),
								 nil),
					  nil);
}

+ (id<GREYMatcher>)detoxMatcherForBoth:(id<GREYMatcher>)firstMatcher and:(id<GREYMatcher>)secondMatcher
{
    return grey_allOf(firstMatcher, secondMatcher, nil);
}

+ (id<GREYMatcher>)detoxMatcherForBoth:(id<GREYMatcher>)firstMatcher andAncestorMatcher:(id<GREYMatcher>)ancestorMatcher
{
    return grey_allOf(firstMatcher, grey_ancestor(ancestorMatcher), nil);
}

+ (id<GREYMatcher>)detoxMatcherForBoth:(id<GREYMatcher>)firstMatcher andDescendantMatcher:(id<GREYMatcher>)descendantMatcher
{
    return grey_allOf(firstMatcher, grey_descendant(descendantMatcher), nil);
}

+ (id<GREYMatcher>)detoxMatcherForNot:(id<GREYMatcher>)matcher
{
    return grey_not(matcher);
}

+ (id<GREYMatcher>)detoxMatcherForClass:(NSString *)aClassName
{
    Class klass = NSClassFromString(aClassName);
    return grey_kindOfClass(klass);
}

@end
