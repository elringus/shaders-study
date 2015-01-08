Shader "Custom/NormalMap" 
{
	Properties 
	{
		_ColorTint ("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
		_DiffuseMap ("Diffuse Map", 2D) = "white" {}
		_NormalMap ("Normal Map", 2D) = "bump" {}
		_BumpDepth ("Bump Depth", float) = 1.0
		_SpecColor ("Specular Color", Color)  = (1.0, 1.0, 1.0, 1.0)
		_SpecPower ("Specular Power", float) = 10.0
		_RimColor ("Rim Color", Color)  = (1.0, 1.0, 1.0, 1.0)
		_RimPower ("Rim Power", float) = 5.0
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
			uniform sampler2D _NormalMap;
			uniform float4 _NormalMap_ST;
			uniform float _BumpDepth;
			uniform float4 _SpecColor;
			uniform float _SpecPower;
			uniform float4 _RimColor;
			uniform float _RimPower;
			
			uniform float4 _LightColor0;
			
			struct vertexInput
			{
				float4 vertex : POSITION;	
				float4 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};
			
			struct vertexOutput
			{
				float4 pos : SV_POSITION;
				float4 texPos : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				float3 tangentDir : TEXCOORD3;
				float3 binormalDir : TEXCOORD4;
			};
			
			
			vertexOutput vert (vertexInput v)
			{
				vertexOutput o;
				
				o.posWorld = mul(_Object2World, v.vertex);
				o.texPos = v.texcoord;
				o.normalDir = normalize(mul(float4(v.normal, 0.0), _World2Object).xyz);
				o.tangentDir = normalize(mul(_Object2World, v.tangent).xyz);
				o.binormalDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
				
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				return o;
			}
			
			float4 frag (vertexOutput o) : COLOR
			{	
				float4 diffuseColor = tex2D(_DiffuseMap, o.texPos.xy * _DiffuseMap_ST.xy + _DiffuseMap_ST.zw);
				float4 normalColor = tex2D(_NormalMap, o.texPos.xy * _NormalMap_ST.xy + _NormalMap_ST.zw);
				
				float3 localNormal = float3(2.0 * normalColor.ag - float2(1.0, 1.0), 0.0);
				localNormal.z = _BumpDepth;
				
				float3x3 localToWorld = float3x3(o.tangentDir, o.binormalDir, o.normalDir);
				
				float3 normalDirection = normalize(mul(localNormal, localToWorld));
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
				
				float3 diffuseReflection = _LightColor0.xyz * saturate(dot(normalDirection, lightDirection));
				float3 specularReflection = _SpecColor * diffuseReflection * 
					pow(saturate(dot(reflect(-lightDirection, normalDirection), viewDirection)), _SpecPower);
				float3 rimReflection = _RimColor * diffuseReflection *
					pow(1.0 - saturate(dot(normalDirection, viewDirection)), _RimPower);
				float3 finalReflection = diffuseReflection + specularReflection + rimReflection + UNITY_LIGHTMODEL_AMBIENT;
				
				return float4(diffuseColor * finalReflection * _ColorTint, 1.0);
			}
			
			ENDCG
		}
		
		Pass
		{
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			uniform sampler2D _NormalMap;
			uniform float4 _NormalMap_ST;
			uniform float _BumpDepth;
			uniform float4 _ColorTint;
			uniform float4 _SpecColor;
			uniform float _SpecPower;
			uniform float4 _RimColor;
			uniform float _RimPower;
			
			uniform float4 _LightColor0;
			
			struct vertexInput
			{
				float4 vertex : POSITION;	
				float4 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};
			
			struct vertexOutput
			{
				float4 pos : SV_POSITION;
				float4 texPos : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				float3 tangentDir : TEXCOORD3;
				float3 binormalDir : TEXCOORD4;
			};
			
			
			vertexOutput vert (vertexInput v)
			{
				vertexOutput o;
				
				o.posWorld = mul(_Object2World, v.vertex);
				o.texPos = v.texcoord;
				o.normalDir = normalize(mul(float4(v.normal, 0.0), _World2Object).xyz);
				o.tangentDir = normalize(mul(_Object2World, v.tangent).xyz);
				o.binormalDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
				
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				return o;
			}
			
			float4 frag (vertexOutput o) : COLOR
			{
				float4 normalColor = tex2D(_NormalMap, o.texPos.xy * _NormalMap_ST.xy + _NormalMap_ST.zw);
				
				float3 localNormal = float3(2.0 * normalColor.ag - float2(1.0, 1.0), 0.0);
				localNormal.z = _BumpDepth;
				
				float3x3 localToWorld = float3x3(o.tangentDir, o.binormalDir, o.normalDir);
				
				float3 normalDirection = normalize(mul(localNormal, localToWorld));
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
				float3 lightDirection;
				float lightAttenuation;
				
				// directional light w-component will always be zero
				// also, if-else construct is VERY heavy, so shouldn't use it (will replace with lerp() in future)
				if (_WorldSpaceLightPos0.w == 0.0)
				{
					lightAttenuation = 1.0;
					lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				}
				else 
				{
					float3 fragToLightSource = _WorldSpaceLightPos0.xyz - o.posWorld.xyz;
					lightAttenuation = 1.0 / length(fragToLightSource);
					lightDirection = normalize(fragToLightSource);
				}
				
				float3 diffuseReflection = lightAttenuation * _LightColor0.xyz * saturate(dot(normalDirection, lightDirection));
				float3 specularReflection = lightAttenuation * _SpecColor * diffuseReflection * 
					pow(saturate(dot(reflect(-lightDirection, normalDirection), viewDirection)), _SpecPower);
				float3 rimReflection = lightAttenuation * _RimColor * diffuseReflection *
					pow(1.0 - saturate(dot(normalDirection, viewDirection)), _RimPower);
				float3 finalReflection = diffuseReflection + specularReflection + rimReflection;
				
				return float4(finalReflection * _ColorTint, 1.0);
			}
			
			ENDCG
		}
	}
	//Fallback "Diffuse"
}
