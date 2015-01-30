Shader "Custom/Final" 
{
	Properties 
	{
		_ColorTint ("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
		_DiffuseMap ("Diffuse Map", 2D) = "white" {}
		_NormalMap ("Normal Map", 2D) = "bump" {}
		_BumpDepth ("Bump Depth", Range(0.0, 1.0)) = 1.0
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
			
			#pragma vertex ComputeVertex
			#pragma fragment ComputeFragment
			
			uniform fixed4 _ColorTint;
			uniform sampler2D _DiffuseMap;
			uniform half4 _DiffuseMap_ST;
			uniform sampler2D _NormalMap;
			uniform half4 _NormalMap_ST;
			uniform fixed _BumpDepth;
			uniform fixed4 _SpecColor;
			uniform half _SpecPower;
			uniform fixed4 _RimColor;
			uniform half _RimPower;
			
			uniform half4 _LightColor0;
			
			struct vertexInput
			{
				half4 vertex : POSITION;	
				half4 texcoord : TEXCOORD0;
				half3 normal : NORMAL;
				half4 tangent : TANGENT;
			};
			
			struct vertexOutput
			{
				half4 pos : SV_POSITION;
				half4 texPos : TEXCOORD0;
				fixed3 normalDir : TEXCOORD1;
				fixed3 tangentDir : TEXCOORD2;
				fixed3 binormalDir : TEXCOORD3;
				fixed3 lightDir : TEXCOORD4;
				fixed3 viewDir : TEXCOORD5;
			};
			
			
			vertexOutput ComputeVertex (vertexInput v)
			{
				vertexOutput o;
				
				o.texPos = v.texcoord;
				o.normalDir = normalize(mul(half4(v.normal, 0.0), _World2Object).xyz);
				o.tangentDir = normalize(mul(_Object2World, v.tangent).xyz);
				o.binormalDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
				o.lightDir = normalize(_WorldSpaceLightPos0.xyz);
				o.viewDir = normalize(_WorldSpaceCameraPos.xyz -  mul(_Object2World, v.vertex).xyz);
				
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				return o;
			}
			
			fixed4 ComputeFragment (vertexOutput o) : COLOR
			{	
				fixed4 diffuseColor = tex2D(_DiffuseMap, o.texPos.xy * _DiffuseMap_ST.xy + _DiffuseMap_ST.zw);
				fixed4 normalColor = tex2D(_NormalMap, o.texPos.xy * _NormalMap_ST.xy + _NormalMap_ST.zw);
				
				fixed3 localNormal = fixed3(2.0 * normalColor.ag - fixed2(1.0, 1.0), _BumpDepth);
				fixed3x3 localToWorld = fixed3x3(o.tangentDir, o.binormalDir, o.normalDir);
				fixed3 normalDirection = normalize(mul(localNormal, localToWorld));
				
				fixed3 diffuseReflection = _LightColor0.xyz * saturate(dot(normalDirection, o.lightDir));
				fixed3 specularReflection = _SpecColor * diffuseReflection * 
					pow(saturate(dot(reflect(-o.lightDir, normalDirection), o.viewDir)), _SpecPower);
				fixed3 rimReflection = _RimColor * diffuseReflection *
					pow(1.0 - saturate(dot(normalDirection, o.viewDir)), _RimPower);
				fixed3 finalReflection = diffuseReflection + specularReflection + rimReflection + UNITY_LIGHTMODEL_AMBIENT;
				
				return fixed4(diffuseColor * finalReflection * _ColorTint, 1.0);
			}
			
			ENDCG
		}
		
		Pass
		{
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			
			CGPROGRAM
			
			#pragma vertex ComputeVertex
			#pragma fragment ComputeFragment
			
			uniform sampler2D _NormalMap;
			uniform half4 _NormalMap_ST;
			uniform fixed _BumpDepth;
			uniform fixed4 _ColorTint;
			uniform fixed4 _SpecColor;
			uniform half _SpecPower;
			uniform fixed4 _RimColor;
			uniform half _RimPower;
			
			uniform half4 _LightColor0;
			
			struct vertexInput
			{
				half4 vertex : POSITION;	
				half4 texcoord : TEXCOORD0;
				half3 normal : NORMAL;
				half4 tangent : TANGENT;
			};
			
			struct vertexOutput
			{
				half4 pos : SV_POSITION;
				half4 texPos : TEXCOORD0;
				fixed3 normalDir : TEXCOORD1;
				fixed3 tangentDir : TEXCOORD2;
				fixed3 binormalDir : TEXCOORD3;
				fixed4 lightDir : TEXCOORD4;
				fixed3 viewDir : TEXCOORD5;
			};
			
			
			vertexOutput ComputeVertex (vertexInput v)
			{
				vertexOutput o;
				
				half4 posWorld = mul(_Object2World, v.vertex);
				
				o.texPos = v.texcoord;
				o.normalDir = normalize(mul(half4(v.normal, 0.0), _World2Object).xyz);
				o.tangentDir = normalize(mul(_Object2World, v.tangent).xyz);
				o.binormalDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - posWorld.xyz);
				
				half3 vertexToLight = _WorldSpaceLightPos0.xyz - posWorld.xyz;
				o.lightDir = fixed4(normalize(lerp(_WorldSpaceLightPos0.xyz, vertexToLight, _WorldSpaceLightPos0.w)), 
					lerp(1.0, 1.0 / length(vertexToLight), _WorldSpaceLightPos0.w));
				
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				return o;
			}
			
			fixed4 ComputeFragment (vertexOutput o) : COLOR
			{
				fixed4 normalColor = tex2D(_NormalMap, o.texPos.xy * _NormalMap_ST.xy + _NormalMap_ST.zw);
				
				fixed3 localNormal = fixed3(2.0 * normalColor.ag - fixed2(1.0, 1.0), _BumpDepth);
				fixed3x3 localToWorld = fixed3x3(o.tangentDir, o.binormalDir, o.normalDir);
				fixed3 normalDirection = normalize(mul(localNormal, localToWorld));
				
				fixed3 diffuseReflection = o.lightDir.w * _LightColor0.xyz * saturate(dot(normalDirection, o.lightDir.xyz));
				fixed3 specularReflection = o.lightDir.w * _SpecColor * diffuseReflection * 
					pow(saturate(dot(reflect(-o.lightDir.xyz, normalDirection), o.viewDir)), _SpecPower);
				fixed3 rimReflection = o.lightDir.w * _RimColor * diffuseReflection *
					pow(1.0 - saturate(dot(normalDirection, o.viewDir)), _RimPower);
				fixed3 finalReflection = diffuseReflection + specularReflection + rimReflection;
				
				return fixed4(finalReflection * _ColorTint, 1.0);
			}
			
			ENDCG
		}
	}
	//Fallback "Diffuse"
}
