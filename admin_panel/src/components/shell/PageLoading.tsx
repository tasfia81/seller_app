/** Lightweight placeholder shown while a page's URL-dependent content streams in. */
export function PageLoading({ title }: { title: string }) {
  const bar = (w: string) => <div style={{ height: 14, width: w, borderRadius: 7, background: "#E7ECE9" }} />;
  return (
    <>
      <header className="tb">
        <h1>{title}</h1>
      </header>
      <main className="ct" aria-busy="true" aria-label="লোড হচ্ছে">
        <div className="cd" style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {bar("40%")}
          {bar("70%")}
          {bar("55%")}
        </div>
      </main>
    </>
  );
}
