Shader "Custom/TextureMap" 
{
	Properties 
	{
		_ColorTint ("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
		_DiffuseMap ("Diffuse Map", 2D) = "white" {}
		_SpecColor ("Specular Color", Color)  = (1.0, 1.0, 1.0, 1.0)
		_SpecPower ("Specular Power", float) = 10
		_RimColor ("Rim Color", Color)  = (1.0, 1.0, 1.0, 1.0)
		_RimPower ("Rim Power", float) = 5
	}
	
	SubShader 
	{
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			uniform float4 _ColorTint;
			uniform sampler2D _DiffuseMap;
			uniform float4 _DiffuseMap_ST;
			uniform float4 _SpecColor;
			uniform float _SpecPower;
			uniform float4 _RimColor;
			uniform float _RimPower;
			
			uniform float4 _LightColor0;
			
			struct vertexInput
			{
				float4 vertex : POSITION;	
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};
			
			struct vertexOutput
			{
				float4 pos : SV_POSITION;
				float4 texPos : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
			};
			
			
			vertexOutput vert (vertexInput v)
			{
				vertexOutput o;
				
				o.posWorld = mul(_Object2World, v.vertex);
				o.normalDir = normalize(mul(float4(v.normal, 0), _World2Object).xyz);
				o.texPos = v.texcoord;
				
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				return o;
			}
			
			float4 frag (vertexOutput o) : COLOR
			{
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
				
				float4 diffuseColor = tex2D(_DiffuseMap, o.texPos.xy * _DiffuseMap_ST.xy + _DiffuseMap_ST.zw);
				
				float3 diffuseReflection = _LightColor0.xyz * saturate(dot(o.normalDir, lightDirection));
				float3 specularReflection = _SpecColor * diffuseReflection * 
					pow(saturate(dot(reflect(-lightDirection, o.normalDir), viewDirection)), _SpecPower);
				float3 rimReflection = _RimColor * diffuseReflection *
					pow(1 - saturate(dot(o.normalDir, viewDirection)), _RimPower);
				float3 finalReflection = diffuseReflection + specularReflection + rimReflection + UNITY_LIGHTMODEL_AMBIENT;
				
				return float4(diffuseColor * finalReflection * _ColorTint, 1);
			}
			
			ENDCG
		}
		
		Pass
		{
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One // how we blend with the previous pass (Blend {source} {dest})
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			uniform float4 _ColorTint;
			uniform float4 _SpecColor;
			uniform float _SpecPower;
			uniform float4 _RimColor;
			uniform float _RimPower;
			
			uniform float4 _LightColor0;
			
			struct vertexInput
			{
				float4 vertex : POSITION;	
				float3 normal : NORMAL;
			};
			
			struct vertexOutput
			{
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD0;
				float3 normalDir : TEXCOORD1;
			};
			
			
			vertexOutput vert (vertexInput v)
			{
				vertexOutput o;
				
				o.posWorld = mul(_Object2World, v.vertex);
				o.normalDir = normalize(mul(float4(v.normal, 0), _World2Object).xyz);
				
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				return o;
			}
			
			float4 frag (vertexOutput o) : COLOR
			{
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
				float3 lightDirection;
				float lightAttenuation;
				
				// directional light w-component will always be zero
				// also, if-else construct is VERY heavy, so shouldn't use it (will replace with lerp() in future)
				if (_WorldSpaceLightPos0.w == 0)
				{
					lightAttenuation = 1;
					lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				}
				else 
				{
					float3 fragToLightSource = _WorldSpaceLightPos0.xyz - o.posWorld.xyz;
					lightAttenuation = 1 / length(fragToLightSource);
					lightDirection = normalize(fragToLightSource);
				}
				
				float3 diffuseReflection = lightAttenuation * _LightColor0.xyz * saturate(dot(o.normalDir, lightDirection));
				float3 specularReflection = lightAttenuation * _SpecColor * diffuseReflection * 
					pow(saturate(dot(reflect(-lightDirection, o.normalDir), viewDirection)), _SpecPower);
				float3 rimReflection = lightAttenuation * _RimColor * diffuseReflection *
					pow(1 - saturate(dot(o.normalDir, viewDirection)), _RimPower);
				float3 finalReflection = diffuseReflection + specularReflection + rimReflection;
				
				return float4(finalReflection * _ColorTint, 1);
			}
			
			ENDCG
		}
	}
	//Fallback "Diffuse"
}
