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


//1. fix jumping.. x appplyimpulse? but no velocity!
//TODO Automate first platform
#import "RVMyScene.h"
#import "RVPlatform.h"
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


-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
//        NSLog(@"%f", size.width);
//        CGSize abcd = size;
//        platform = [abc init:abcd];
        
        self.backgroundColor = [SKColor blackColor];
        self.physicsWorld.contactDelegate = self;
        platformsArray = [NSMutableArray array];

//        self.physicsWorld.gravity = CGVectorMake(0, 0);
        platform = [[RVPlatform alloc ]init:size];
        [platform setPosition:CGPointMake(platform.size.width/2, platform.size.height/2)];
        
        SKAction *movePlatform = [SKAction moveBy:CGVectorMake(-100, 0) duration: 2];
        //    SKAction *scalePlatform = [SKAction scaleYTo:0.8 duration:20];
        //    SKAction *foreverG = [SKAction group:@[movePlatform, scalePlatform]];
        forever = [SKAction repeatActionForever:movePlatform];

        [platform runAction:forever];
        [platformsArray addObject:platform];

//        [self addChild:platform];
//        
//        int prevPositionX = platform.position.x;
//        int prevSpace = 50;
//        int prevWidth = platform.size.width;
//        platform = [[RVPlatform alloc]init:self.size];
//        [platform setPosition:CGPointMake(prevPositionX+prevWidth/2+prevSpace+platform.size.width/2, platform.size.height/2)];
////        [platformsArray addObject:platform];
//
//        [platform runAction:forever];
////        [self addChild:platform];
//        
        
         int prevPositionX = platform.position.x;
         int prevSpace = 50;
         int prevWidth = platform.size.width;

        [platformsArray addObject:[[[RVPlatform alloc]init:self.size] setNewPositionAndRunAction:(int)(prevPositionX+prevWidth/2+prevSpace) :forever]];

        CGPoint prevpos = [platformsArray.lastObject position];
        CGSize prevwid = [platformsArray.lastObject size];
        
        [platformsArray addObject:[[[RVPlatform alloc]init:self.size] setNewPositionAndRunAction:(int)(prevpos.x+prevwid.width/2+prevSpace) :forever]];
        NSLog(@"%lu", (unsigned long)platformsArray.count);
        for(int i = 0; i < [platformsArray count]; i++){
            [self addChild:platformsArray[i]];
        }
        
        
//        self.physicsWorld.gravity = CGVectorMake(0, 0);
        ball = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(15, 15)];
        ball.position = CGPointMake(ball.size.width/2+5, self.size.height/2);
        ball.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:ball.size];
        ball.physicsBody.friction = 0;
//        ball.physicsBody.restitution = 0;
        ball.physicsBody.categoryBitMask = ballCat;
        ball.physicsBody.contactTestBitMask = smallBlockCat | platformCat | bigBlockCat;
        ball.physicsBody.collisionBitMask = platformCat;
//        ball.physicsBody.velocity = CGVectorMake(90, 0);
        ball.physicsBody.allowsRotation = NO;
//        [ball.physicsBody applyImpulse:CGVectorMake(20, 0)];
//        [self generatePlatforms:size];
//        platform.physicsBody.velocity = CGVectorMake(-60, 0);

        [self generateSmallBlocks:size];
        [self generateBigBlocks:size];

        
        
        score = [SKLabelNode labelNodeWithFontNamed:@"AppleSDGothicNeo-Regular"];
        score.fontSize = 20;
        score.text = [NSString stringWithFormat:@"Score: %d", totalScore];
        score.position = CGPointMake(size.width/2, size.height-40);
//        score.position = CGPointMake(size.width, size.height);
        [self addChild:score];
//        smallBlock.physicsBody.contactTestBitMask = smallBlockCat;

        
        
        
        [self addChild:ball];

    }
    return self;
}

-(void)generateSmallBlocks:(CGSize)size{
    float oldSmallBlockSize = 0;
    for(int i = 0; i < 5; i++){
//        if(lastSmallBlockSize > 0){
//            smallBlock = [SKSpriteNode spriteNodeWithColor:[SKColor greenColor] size:CGSizeMake(10, 10)];
//            smallBlock.position = CGPointMake(lastSmallBlockSize+100+smallBlock.size.width/2, size.height/2+smallBlock.size.height/2);
//            smallBlock.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:smallBlock.size];
//            smallBlock.physicsBody.dynamic = NO;
//            smallBlock.physicsBody.categoryBitMask = smallBlockCat;
//            oldSmallBlockSize = smallBlock.position.x+smallBlock.size.width;
//        } else {
        smallBlock = [SKSpriteNode spriteNodeWithColor:[SKColor greenColor] size:CGSizeMake(10, 10)];
        smallBlock.position = CGPointMake([self generateRandNumber:rSPACE :size], size.height/2+smallBlock.size.height/2);
        smallBlock.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:smallBlock.size];
        smallBlock.physicsBody.dynamic = NO;
        smallBlock.physicsBody.categoryBitMask = smallBlockCat;
        oldSmallBlockSize = smallBlock.position.x+smallBlock.size.width;
//        }
        if(i == 4){
            smallBlock.name = @"lastSmallBlock";
            smallBlock.color = [SKColor blueColor];
            lastSmallBlockSize = smallBlock.position.x+smallBlock.size.width;
        }
        [smallBlock runAction:forever];
        [self addChild:smallBlock];
    }
}

-(void)generateBigBlocks:(CGSize)size{
    float oldBigBlockSize = 0;
    for(int i = 0; i < 5; i++){
        
//        if(i == 0){
//            bigBlock = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(10, 20)];
//            bigBlock.position = CGPointMake(lastSmallBlockSize+100+bigBlock.size.width/2, size.height/2+bigBlock.size.height/2);
//            bigBlock.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:bigBlock.size];
//            bigBlock.physicsBody.dynamic = NO;
//            bigBlock.physicsBody.categoryBitMask = bigBlockCat;
//            oldBigBlockSize = bigBlock.position.x+bigBlock.size.width;
//        } else {
            bigBlock = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(10, 20)];
            bigBlock.position = CGPointMake([self generateRandNumber:rSPACE :size], size.height/2+bigBlock.size.height/2);
            bigBlock.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:bigBlock.size];
            bigBlock.physicsBody.dynamic = NO;
            bigBlock.physicsBody.categoryBitMask = bigBlockCat;
            oldBigBlockSize = bigBlock.position.x+bigBlock.size.width;
//        }
        if(i == 4){
            bigBlock.name = @"lastBigBlock";
            bigBlock.color = [SKColor blueColor];
        }
        [bigBlock runAction:forever];
        [self addChild:bigBlock];
    }
}

-(int)generateRandNumber:(int)rType :(CGSize)size{
//    totalScore++;
    int randNumber = 0;
    int min = 50;
    if(rType == 1){ //Width
        randNumber = arc4random() % ((int)size.width - min) + 50;
    }
    if(rType == 2){ //Space
        randNumber = arc4random() % (int)size.width;
    }
    return randNumber;
};

//-(void) generateSinglePlatform:(CGSize)size :(SKSpriteNode*)lastPlatform{
//    
//    
//    
//}


-(void) generatePlatforms:(CGSize)size{
    
    

    
    

    
//    for(int i = 0; i < 3; i++){
//    int randSpace = [self generateRandNumber:rSPACE :size];
    SKAction *movePlatform = [SKAction moveBy:CGVectorMake(-100, 0) duration: 2];
    SKAction *forever = [SKAction repeatActionForever:movePlatform];
    int space1 = 20;
    int space2 = 200;
    int space3 = 300;
    
    if(addedPlatform){
    
        platform = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake([self generateRandNumber:rWIDTH :size], size.height/2)];
        platform.position = CGPointMake(platform2.position.x+platform2.size.width/2+space1+platform.size.width/2, platform.size.height/2);
        platform.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:platform.size];
        platform.physicsBody.dynamic = NO;
        platform.physicsBody.categoryBitMask = platformCat;
//        space1 += 300;
        space2 += 300;
        space3 += 300;
        totalWidth = platform.size.width;
    }else {
    
    platform = [SKSpriteNode spriteNodeWithColor:[SKColor blueColor] size:CGSizeMake([self generateRandNumber:rWIDTH :size], size.height/2)];
    platform.position = CGPointMake(platform.size.width/2, platform.size.height/2);
    platform.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:platform.size];
    platform.physicsBody.dynamic = NO;
    platform.physicsBody.categoryBitMask = platformCat;
        oldSize = platform.size.width;
        totalWidth += platform.size.width;
        
      

    }
  
    
    
    platform1 = [SKSpriteNode spriteNodeWithColor:[SKColor brownColor] size:CGSizeMake([self generateRandNumber:rWIDTH :size], size.height/2)];
    platform1.position = CGPointMake(platform.size.width/2+platform.position.x+space1+platform1.size.width/2, platform1.size.height/2);
    platform1.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:platform1.size];
    platform1.physicsBody.dynamic = NO;
    platform1.physicsBody.categoryBitMask = platformCat;
    totalWidth += platform1.size.width;
    [platform1 runAction:forever];
    
    [self addChild:platform1];
    
    
    platform2 = [SKSpriteNode spriteNodeWithColor:[SKColor grayColor] size:CGSizeMake([self generateRandNumber:rWIDTH :size], size.height/2)];
    platform2.position = CGPointMake(platform1.position.x+platform1.size.width/2+space1+platform2.size.width/2, platform2.size.height/2);
    platform2.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:platform2.size];
    platform2.physicsBody.dynamic = NO;
    platform2.physicsBody.categoryBitMask = platformCat;
    platform2.name = @"lastPlatform";
    totalWidth += platform2.size.width;
    [platform2 runAction:forever];
    [self addChild:platform2];

    
//
//
//    SKSpriteNode *platform2 = [SKSpriteNode spriteNodeWithColor:[SKColor blueColor] size:CGSizeMake(randWidth, size.height/2)];
//    platform2.position = CGPointMake(platform.size.width+randSpace+platform.size.width/2, platform1.size.height/2);
//    platform2.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:platform1.size];
//    platform2.physicsBody.dynamic = NO;
//    platform2.physicsBody.categoryBitMask = platformCat;


    [platform runAction:forever];

    [self addChild:platform];

//    }

}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
//    platform.physicsBody.velocity = platform.physicsBody.velocity;
    SKAction *movePlatform = [SKAction moveBy:CGVectorMake(-100, 0) duration: 1];
    //    SKAction *scalePlatform = [SKAction scaleYTo:0.8 duration:20];
    //    SKAction *foreverG = [SKAction group:@[movePlatform, scalePlatform]];
    SKAction *forever = [SKAction repeatActionForever:movePlatform];
    NSLog(@"%@", platformsArray[0]);
    for(int i = 0; i < [platformsArray count]; i++){
        NSLog(@"%@", platformsArray[i]);
        [platformsArray[i] runAction:forever];
    }
    
    
    if(onAir == false){
        touched++;
        appliedImpulse = true;
//    ball.physicsBody.velocity = CGVectorMake(0, 0);
    [ball.physicsBody applyImpulse:CGVectorMake(0, 3)];
//        [platform.physicsBody applyImpulse:CGVectorMake(-20, 0)];
//                [platform1.physicsBody applyImpulse:CGVectorMake(-20, 0)];
//                [platform2.physicsBody applyImpulse:CGVectorMake(-20, 0)];
//        SKAction *movePlatform = [SKAction moveBy:CGVectorMake(-400, 0) duration: 2];
//        SKAction *forever = [SKAction repeatActionForever:movePlatform];
//
//        [platform runAction:forever];
//        [platform1 runAction:forever];
//        [platform2 runAction:forever];
//        ball.physicsBody.velocity = CGVectorMake(0, 0);

    }
//    [ball.physicsBody applyForce:CGVectorMake(0, 10)];
    
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
//                NSLog(@"Started Contact");
//        if(touched > 0){ //Put this if statement in the correct place!
//            ball.physicsBody.velocity = CGVectorMake(0, 0);
//        }
//        if(appliedImpulse == true){
            onAir = false;
//        }
    }
    
    
//        NSLog(@"%d", touched);
    
}

-(void)didEndContact:(SKPhysicsContact *)contact{
    SKPhysicsBody *notBall;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask){
        
        notBall = contact.bodyB;
    } else {
        notBall = contact.bodyA;
        
    }
    
    if(notBall.categoryBitMask == platformCat){
//        NSLog(@"Ended Contact");
       
//        if(appliedImpulse == true){

//        if(appliedImpulse == true){
//            touchedGround = false;
//        } else {
//            touchedGround = true;
//        }
    }
}

-(void)update:(CFTimeInterval)currentTime {
    if(platform.position.x+platform.size.width < self.size.width){
        
//        RVPlatform *platform;

        
        
        
        
        
    }
    
    
    if(!addedPlatform){
    if(platform2.position.x < self.size.width){
        addedPlatform = YES;
//        [self generatePlatforms:self.size]; //Change to generate platform (single)
    }
    }
    if(touched == 2){
        touched = 0;
        onAir = true;}

    if(addedPlatform){
        if(platform2.position.x < self.size.width){
            addedPlatform = NO;
        }
    }
}

@end
