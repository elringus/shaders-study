Shader "Custom/FlatColor" 
{
	Properties 
	{
		_Color ("Color", Color) = (255, 255, 255, 255)
	}
	
	SubShader 
	{
		Pass
		{
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			uniform float4 _Color;
			
			struct vertexInput
			{
				float4 vertex : POSITION;	
			};
			
			struct vertexOutput
			{
				float4 pos : SV_POSITION;
			};
			
			
			vertexOutput vert (vertexInput v)
			{
				vertexOutput o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				return o;
			}
			
			float4 frag (vertexOutput o) : COLOR
			{
				return _Color;
			}
			
			ENDCG
		}
	}
}
