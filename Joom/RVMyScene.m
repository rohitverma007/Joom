//
//  RVMyScene.m
//  Joom
//
//  Created by Rohit Verma on 2014-07-19.
//  Copyright (c) 2014 rohitv. All rights reserved.
//

//TODO
//Look into optimizing.. fps decreases, cpu increases? memory management?
//Fix the generator, clean up code, check if good idea to put it in update? .. use similar logic as small/big blocks for loop?
//Fix ball moving back a bit?
//Implement random height, random space
//Implement smallBlocks, bigBlocks
//Implement power ups
//Implement score
//Implement main menu/ game over - retry
//Check difference between adding public variables here or in .h file...
//Remove platformCat?
//Hide status bar
//look into intenrary if statements/shortcut variable if statements

//Square is running away from the left side of the screen! save him, dont let him get eaaaaten

//1. fix jumping.. x appplyimpulse? but no velocity!
//TODO Automate first platform
//TODO Figure out how to set action properly... currently thinking of implementing delegates?
// Currently resetting action... should only modify it temporarily? maybe use callbacks???
#import "RVMyScene.h"
#import "RVPlatform.h"
#import "RVHelper.h"

//MOve these to rvhelper maybe?
static const uint32_t ballCat = 1;
static const uint32_t platformCat = 2;
static const uint32_t smallBlockCat = 4;
static const uint32_t bigBlockCat = 8;
@implementation RVMyScene
NSMutableArray *platformsArray;
SKSpriteNode *ball;
//SKSpriteNode *platform;
BOOL touchingGround = NO;
RVPlatform *platform;
RVPlatform *platform1;
SKSpriteNode *smallBlock;
SKSpriteNode *bigBlock;
RVPlatform *platform2;
SKLabelNode *score;
SKAction *forever;
BOOL addedPlatform = NO;
float totalWidth = 0;
float oldSize = 0;
float lastSmallBlockSize = 0;
float lastBigBlockSize = 0;
const int rWIDTH = 1;
const int rSPACE = 2;
int totalScore = 0;
BOOL appliedImpulse = false;
BOOL onAir = false;
int touched = 0;
bool addedBigBlocks = false;
bool addedSmallBlocks = false;

-(SKAction*)getAction{
    return forever;
}

-(void)setAction:(SKAction*)movePlat :(BOOL)isForever{
    
    SKAction* movePlatform = movePlat;
    if(isForever){
        forever = [SKAction repeatActionForever:movePlatform];
    } else {
        forever = movePlatform;
    }
    
}

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor blueColor];
        self.physicsWorld.contactDelegate = self;
        
        platformsArray = [NSMutableArray array];

        platform = [[RVPlatform alloc ]init:size];
        [platform setPosition:CGPointMake(platform.size.width/2, platform.size.height/2)];
        
        [self setAction:[SKAction moveBy:CGVectorMake(-350, 0) duration: 3] :true];
        
        [platform runAction:[self getAction]];
        [platformsArray addObject:platform];
        
        [platformsArray addObject:[[[RVPlatform alloc]init:self.size] setNewPositionAndRunAction:(int)([RVHelper getDistance:platformsArray.lastObject]) :[self getAction]]];
        
        [platformsArray addObject:[[[RVPlatform alloc]init:self.size] setNewPositionAndRunAction:(int)([RVHelper getDistance:platformsArray.lastObject]) :[self getAction]]];
        
        for(int i = 0; i < [platformsArray count]; i++){
            [self addChild:platformsArray[i]];
        }
        
        
        //TODO - Move into a function or seperate class for reuse in other scenes
        ball = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(25, 25)];
        ball.position = CGPointMake(ball.size.width/2+20, self.size.height/2);
        ball.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:ball.size];
        ball.physicsBody.friction = 0;
        ball.physicsBody.categoryBitMask = ballCat;
        ball.physicsBody.contactTestBitMask = smallBlockCat | platformCat | bigBlockCat;
        ball.physicsBody.collisionBitMask = platformCat;
        ball.physicsBody.allowsRotation = NO;
        
        //TODO Maybe move these two functions to a class for reuse in other scenes?
        [self generateSmallBlocks:size];
        [self generateBigBlocks:size];
        
        
        //Helper function maybe?
        score = [SKLabelNode labelNodeWithFontNamed:@"AppleSDGothicNeo-Regular"];
        score.fontSize = 20;
        score.text = [NSString stringWithFormat:@"Score: %d", totalScore];
        score.position = CGPointMake(size.width/2, size.height-40);
        [self addChild:score];
        
        [self addChild:ball];
        
    }
    return self;
}

-(void)generateSmallBlocks:(CGSize)size{
    float oldSmallBlockSize = 0;
    for(int i = 0; i < 5; i++){

        smallBlock = [SKSpriteNode spriteNodeWithColor:[SKColor greenColor] size:CGSizeMake(10, 10)];
        smallBlock.position = CGPointMake([RVHelper generateRandNumber:rSPACE :size], size.height/2+smallBlock.size.height/2);
        smallBlock.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:smallBlock.size];
        smallBlock.physicsBody.dynamic = NO;
        smallBlock.physicsBody.categoryBitMask = smallBlockCat;
        oldSmallBlockSize = smallBlock.position.x+smallBlock.size.width;
        if(i == 4){
            smallBlock.name = @"lastSmallBlock";
            smallBlock.color = [SKColor blackColor];
            lastSmallBlockSize = smallBlock.position.x+smallBlock.size.width;
        }
        [smallBlock runAction:forever];
        [self addChild:smallBlock];
    }
}

-(void)generateBigBlocks:(CGSize)size{
    float oldBigBlockSize = 0;
    for(int i = 0; i < 5; i++){
        
        bigBlock = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(10, 20)];
        bigBlock.position = CGPointMake([RVHelper generateRandNumber:rSPACE :size], size.height/2+bigBlock.size.height/2);
        bigBlock.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:bigBlock.size];
        bigBlock.physicsBody.dynamic = NO;
        bigBlock.physicsBody.categoryBitMask = bigBlockCat;
        oldBigBlockSize = bigBlock.position.x+bigBlock.size.width;

        if(i == 4){
            bigBlock.name = @"lastBigBlock";
            bigBlock.color = [SKColor blackColor];
        }
        [bigBlock runAction:forever];
        [self addChild:bigBlock];
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if(onAir == false){
        touched++;
        appliedImpulse = true;
        [ball.physicsBody applyImpulse:CGVectorMake(0, 12)];
    }
    
}


-(void)didBeginContact:(SKPhysicsContact *)contact{
    SKPhysicsBody *notBall;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask){
        
        notBall = contact.bodyB;
    } else {
        notBall = contact.bodyA;
        
    }
    
    
    if(notBall.categoryBitMask == smallBlockCat){
        [notBall.node removeFromParent];
        totalScore++;
        score.text = [NSString stringWithFormat:@"Score: %d", totalScore];
        
        //Scaling yes or no?
        //        SKAction *scaleBy = [SKAction scaleBy:1.3 duration:2];
        //        [ball runAction:scaleBy];
        //        if(touched > 0){ //Put this if statement in the correct place!
        //            ball.physicsBody.velocity = CGVectorMake(0, 0);
        //        }
        if([notBall.node.name isEqualToString:@"lastSmallBlock"]){
            [self generateSmallBlocks:self.frame.size];
        }
    }
    
    //For now scale down? oo maybe scale down to original and then if one more touched, then die,
    // maybe in diferent mode , die by touching one?
    if(notBall.categoryBitMask == bigBlockCat){
        [notBall.node removeFromParent];
        totalScore--;
        score.text = [NSString stringWithFormat:@"Score: %d", totalScore];
        //Scaling yes or no?
        //        SKAction *scaleBy = [SKAction scaleBy:0.8 duration:2];
        //        [ball runAction:scaleBy];
        
        //        if(touched > 0){ //Put this if statement in the correct place!
        //            ball.physicsBody.velocity = CGVectorMake(0, 0);
        //        }
        if([notBall.node.name isEqualToString:@"lastBigBlock"]){
            [self generateBigBlocks:self.frame.size];
        }
    }
    
    
    if(notBall.categoryBitMask == platformCat){
        onAir = false;
    }
    
}

-(void)generatePlatforms{
  
    [platformsArray addObject:[[[RVPlatform alloc]init:self.size] setNewPositionAndRunAction:(int)([RVHelper getDistance:platformsArray.lastObject]) :[self getAction]]];
    [self addChild:platformsArray.lastObject];
    [platformsArray addObject:[[[RVPlatform alloc]init:self.size] setNewPositionAndRunAction:(int)([RVHelper getDistance:platformsArray.lastObject]) :[self getAction]]];
    [self addChild:platformsArray.lastObject];
    
    [platformsArray addObject:[[[RVPlatform alloc]init:self.size] setNewPositionAndRunAction:(int)([RVHelper getDistance:platformsArray.lastObject]) :[self getAction]]];
    [self addChild:platformsArray.lastObject];
}

-(void)update:(CFTimeInterval)currentTime {
    
    //TODO Clean up memory! platformsArray!
    NSLog(@"%lu", (unsigned long)platformsArray.count);
    
    
    CGPoint lastObject = [platformsArray.lastObject position];
//    CGPoint lastBigBlockPosition = [[self childNodeWithName:@"lastBigBlock"]position];

//    if(!addedBigBlocks){
//        if(lastBigBlockPosition.x < 50){
//            addedBigBlocks = true;
//            [self generateBigBlocks:self.size];
//        }
//    }
    
//    if(addedBigBlocks){
//        if(lastBigBlockPosition.x < 50){
//            addedBigBlocks = false;
//        }
//    }
    
    if(!addedPlatform){
        if(lastObject.x < self.size.width){
            addedPlatform = YES;
            [self generatePlatforms];
        }
    }
    
    if(touched == 2){
        touched = 0;
        onAir = true;
    }
    
    if(addedPlatform){
        if(lastObject.x < self.size.width){
            addedPlatform = NO;
        }
    }
    
    
}

@end
