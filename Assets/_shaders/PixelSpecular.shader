Shader "Custom/PixelSpecular" 
{
	Properties 
	{
		_Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_SpecColor ("Specular Color", Color)  = (1.0, 1.0, 1.0, 1.0)
		_SpecPower ("Specular Power", Float) = 10
	}
	
	SubShader 
	{
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			uniform float4 _Color;
			uniform float4 _SpecColor;
			uniform float _SpecPower;
			
			uniform float4 _LightColor0;
			
			struct vertexInput
			{
				float4 vertex : POSITION;	
				float3 normal : NORMAL;
			};
			
			struct vertexOutput
			{
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD0; // assuming we have no texture here, so the 0 slot is free
				float3 normalDir : TEXCOORD1;
			};
			
			
			vertexOutput vert (vertexInput v)
			{
				vertexOutput o;
				
				o.posWorld = mul(v.vertex, _Object2World);
				o.normalDir = normalize(mul(float4(v.normal, 0.0), _World2Object).xyz);
				
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				return o;
			}
			
			float4 frag (vertexOutput o) : COLOR
			{
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
				
				float3 diffuseReflection = _LightColor0.xyz * max(0.0, dot(o.normalDir, lightDirection));
				float3 specularReflection = _SpecColor.rgb * max(0.0, dot(o.normalDir, lightDirection)) * 
					pow(max(0.0, dot(reflect(-lightDirection, o.normalDir), viewDirection)), _SpecPower);
				float3 finalReflection = _Color.rgb * (diffuseReflection + specularReflection + UNITY_LIGHTMODEL_AMBIENT);
				
				return float4(finalReflection, 1.0);
			}
			
			ENDCG
		}
	}
	//Fallback "Diffuse"
}
