
struct VS_INPUT
{
   float3 ssPosition   : POSITION;
   float2 texCoord     : TEXCOORD0;
   float4 color        : COLOR0;
};

struct VS_OUTPUT
{
   float4 ssPosition    : POSITION;
   float2 texCoord     : TEXCOORD0;
   float4 color        : COLOR0;
};

struct PS_INPUT
{
   float2 texCoord     : TEXCOORD0;
   float4 color        : COLOR0;
};

texture     baseTexture;
texture     depthTexture;
float       time;
float       startTime;
float       amount;

sampler baseTextureSampler = sampler_state
   {
       texture       = (baseTexture);
       AddressU      = Wrap;
       AddressV      = Wrap;
       MinFilter     = Linear;
       MagFilter     = Linear;
       MipFilter     = Linear;
        SRGBTexture   = False;
   };
   
sampler depthTextureSampler = sampler_state
   {
       texture       = (depthTexture);
       AddressU      = Clamp;
       AddressV      = Clamp;
       MinFilter     = Linear;
       MagFilter     = Linear;
       MipFilter     = None;
        SRGBTexture   = False;
   };   

/**
* Vertex shader.
*/  
VS_OUTPUT SFXBasicVS(VS_INPUT input)
{

   VS_OUTPUT output;

   output.ssPosition = float4(input.ssPosition, 1);
   output.texCoord   = input.texCoord;
   output.color      = input.color;

   return output;

}

float4 SFXDarkVisionPS(PS_INPUT input) : COLOR0
{

    float2 depth1    = tex2D(depthTextureSampler, input.texCoord).rg;
    float4 inputPixel = tex2D(baseTextureSampler, input.texCoord);
	
	const float offset = 0.0005 + depth1.g * 0.001;
	float  depth2 = tex2D(depthTextureSampler, input.texCoord + float2( offset,  offset)).rg;
	float  depth3 = tex2D(depthTextureSampler, input.texCoord + float2( offset, -offset)).rg;
	float  depth4 = tex2D(depthTextureSampler, input.texCoord + float2(-offset, -offset)).rg;
	float  depth5 = tex2D(depthTextureSampler, input.texCoord + float2(-offset,  offset)).rg;
	
	float edge;
    float4 edgeColor;
	
	if (depth1.g > 0.5)    
	{		
		edge = (abs(depth2 - depth1.r) + 
			abs(depth3 - depth1.r) + 
			abs(depth4 - depth1.r) + 
			abs(depth5 - depth1.r ));
			
		if (depth1.r < 0.2)
		{            
			return inputPixel;
		}
		else
		{
			edgeColor = float4(1.0, 0.05, 0.0, 0) * 8.0;
		}		    
	}
	else
	{
		return inputPixel;
	}
	
	const float gray = inputPixel.r * 0.4 + inputPixel.g * 0.4 + inputPixel.b * 0.4;

	float4 details = float4( gray + inputPixel.r * 0.4, gray + inputPixel.g * 0.4, gray + inputPixel.b * 0.4, 0);
	
	return lerp(inputPixel, (details * (.11 + edge) + edgeColor * saturate(edge)) * amount, amount );
   
}
technique SFXDarkVision
{
   pass p0
   {
       ZEnable             = False;
       ZWriteEnable        = False;   
       VertexShader        = compile vs_3_0 SFXBasicVS();
       PixelShader         = compile ps_3_0 SFXDarkVisionPS();
       CullMode            = None;
   }
}
