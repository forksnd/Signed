//
//  Metal.h
//  Signed
//
//  Created by Markus Moenig on 25/8/20.
//

#ifndef Metal_h
#define Metal_h

#include <simd/simd.h>

typedef struct
{
    vector_float2   position;
    vector_float2   textureCoordinate;
} VertexUniform;

typedef struct
{
    vector_float2   screenSize;
    vector_float2   pos;
    vector_float2   size;
    float           globalAlpha;

} TextureUniform;

typedef struct
{
    vector_float4   fillColor;
    vector_float4   borderColor;
    float           radius;
    float           borderSize;
    float           rotation;
    float           onion;
    
    int             hasTexture;
    vector_float2   textureSize;
} DiscUniform;

typedef struct
{
    vector_float2   screenSize;
    vector_float2   pos;
    vector_float2   size;
    float           round;
    float           borderSize;
    vector_float4   fillColor;
    vector_float4   borderColor;
    float           rotation;
    float           onion;
    
    int             hasTexture;
    vector_float2   textureSize;

} BoxUniform;

typedef struct
{
    vector_float2   atlasSize;
    vector_float2   fontPos;
    vector_float2   fontSize;
    vector_float4   color;
} TextUniform;

typedef struct
{
    float           time;
    unsigned int    frame;
} MetalData;

typedef struct {
    
    simd_float3         randomVector;

    int                 samples;
    int                 depth;
    int                 maxDepth;
        
    // bbox
    simd_float3         P;
    simd_float3         L;
    matrix_float3x3     F;
    
    float               maxDistance;
} GPUFragmentUniforms;

typedef struct {
    
    simd_float3         randomVector;

    simd_float3         cameraOrigin;
    simd_float3         cameraLookAt;
    
    int                 samples;
    int                 depth;
    int                 maxDepth;
        
    // bbox
    simd_float3         P;
    simd_float3         L;
    matrix_float3x3     F;
    
    float               maxDistance;
} RenderUniform;

typedef struct {
    
    simd_float3         randomVector;
    
    simd_float2         uv;
    simd_float2         size;
    
    float               scale;
    
    simd_float3         cameraOrigin;
    simd_float3         cameraLookAt;
    
} ModelerHitUniform;

#define Modeler_None            0
#define Modeler_Add             1

#define Modeler_Sphere          0
#define Modeler_Box             1

typedef struct {
    
    int                 actionType;
    int                 primitiveType;
    
    simd_float3         randomVector;

    simd_float3         position;
    simd_float3         rotation;
    
    float               radius;
    
    simd_float3         size;
    float               rounding;

    int                 samples;
    int                 depth;
    int                 maxDepth;
        
    // bbox
    simd_float3         P;
    simd_float3         L;
    matrix_float3x3     F;
    
    float               maxDistance;
} ModelerUniform;

#endif /* Metal_h */
