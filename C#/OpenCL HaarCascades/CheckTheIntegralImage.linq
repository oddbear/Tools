<Query Kind="Statements">
  <NuGetReference>OpenCV.Net</NuGetReference>
  <Namespace>System.Drawing</Namespace>
  <Namespace>System.Drawing.Imaging</Namespace>
  <Namespace>System.Runtime.InteropServices</Namespace>
</Query>

var file = @".\integral.bmp";


using(var cvImage = OpenCV.Net.CV.LoadImage(file, OpenCV.Net.LoadImageFlags.Grayscale))
{
	for(int y = 0; y < 4; y++)
	{
		for(int x = 0; x < 4; x++)
			Console.Write(cvImage[y * 4 + x].Val0.ToString().PadLeft(3, '0') + " ");
		Console.WriteLine();
	}
	
	var sum = new OpenCV.Net.IplImage(new OpenCV.Net.Size(cvImage.Width +1, cvImage.Height +1), OpenCV.Net.IplDepth.F32, cvImage.Channels);
	OpenCV.Net.CV.Integral(cvImage, sum, null, null);
	Console.WriteLine("----------------");
	
	for(int y = 0; y < 5; y++)
	{
		for(int x = 0; x < 5; x++)
			Console.Write(sum[y * 5 + x].Val0.ToString().PadLeft(3, '0') + " ");
		Console.WriteLine();
	}
}